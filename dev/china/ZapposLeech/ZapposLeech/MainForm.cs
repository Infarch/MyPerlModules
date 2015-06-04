using System;
using System.Collections.Generic;
using System.Collections.Concurrent;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.Drawing.Text;
using System.Linq;
using System.Text;
using System.Windows.Forms;
using System.Text.RegularExpressions;
using System.Threading;
using System.Threading.Tasks;
using System.Globalization;
using System.IO;

namespace ZapposLeech
{
    public partial class MainForm : Form
    {
        
        private static string CONNECTION_ERROR = "CHECK THE INTERNET CONNECTION!";
        private static string CONVERSION_ERROR = "CANNOT CONVERT A PICTURE!";

        private static int SLEEPING_TIME = 3000;

        DateTime started;

        public MainForm()
        {
            InitializeComponent();
        }

        private int[] GetStandardFontSizes()
        {
            return new int[] { 12, 14, 16, 18, 20, 22, 24, 26, 28, 36, 48, 72 };
        }

        private void MainForm_Load(object sender, EventArgs e)
        {
            // init fonts
            var fonts = new InstalledFontCollection();
            var families = fonts.Families;
            cbFonts.DataSource = families;
            cbFonts.DisplayMember = "Name";
            
            // look for the initial font
            FontFamily initialFamily = families.FirstOrDefault(x => x.Name == "Arial");
            if (initialFamily != default(FontFamily)) cbFonts.SelectedItem = initialFamily;

            // init font sizes
            cbBrandFontSize.DataSource = GetStandardFontSizes();
            cbBrandFontSize.SelectedItem = 48;

            cbNameSize.DataSource = GetStandardFontSizes();
            cbNameSize.SelectedItem = 26;

            cbBottomSize.DataSource = GetStandardFontSizes();
            cbBottomSize.SelectedItem = 36;

            progress.Maximum = 100;

            //Uri test = new Uri("http://www.zappos.com/jack-by-bb-dakota-daniela-dress-black");
            //string data = Web.GetContent(test);
            //Console.WriteLine(data.Length);
        }


        private void btnSelectFolder_Click(object sender, EventArgs e)
        {
            if (dlgTargetFolder.ShowDialog() == DialogResult.OK) tbFolder.Text = dlgTargetFolder.SelectedPath;
        }

        private void btnRunTask_Click(object sender, EventArgs e)
        {
            if(!ValidForm()) return;
            
            SetControlState(false);

            Uri target = new Uri(tbUrl.Text);
            // check whether there is any filter
            Match mUriFilter = RE.UriFilter.Match(tbUrl.Text);
            if (mUriFilter.Success)
                target = new Uri(target, mUriFilter.Groups[1].Value);
            // create config
            Config cfg = new Config(
                tbFolder.Text,
                target,
                tbSkuPrefix.Text,
                (FontFamily)cbFonts.SelectedValue,
                Int32.Parse(tbPricePercents.Text),
                (int)cbBrandFontSize.SelectedValue,
                (int)cbNameSize.SelectedValue,
                (int)cbBottomSize.SelectedValue,
                (int)photoLimit.Value,
                (int)directoryLimit.Value);
            
            started = DateTime.Now;

            worker.RunWorkerAsync(cfg);
        }

        private void SetControlState(bool state)
        {
            tbUrl.Enabled = state;
            btnSelectFolder.Enabled = state;
            tbSkuPrefix.Enabled = state;
            tbPricePercents.Enabled = state;
            cbFonts.Enabled = state;
            cbBrandFontSize.Enabled = state;
            cbNameSize.Enabled = state;
            cbBottomSize.Enabled = state;
            btnRunTask.Enabled = state;
            photoLimit.Enabled = state;
            directoryLimit.Enabled = state;
            progress.Visible = !state;
        }

        private void MarkValid(Control c)
        {
            errorProvider.SetError(c, String.Empty);
        }

        private void MarkInvalid(Control c, string p)
        {
            errorProvider.SetIconAlignment(c, ErrorIconAlignment.MiddleRight);
            errorProvider.SetIconPadding(c, 2);
            errorProvider.SetError(c, p);
        }

        private bool ValidForm()
        {
            if (String.IsNullOrWhiteSpace(tbUrl.Text)) 
            {
                MarkInvalid(tbUrl, "The url must not be empty");
                return false;
            }
            MarkValid(tbUrl);

            if (String.IsNullOrWhiteSpace(tbFolder.Text))
            {
                MarkInvalid(tbFolder, "You must specify a folder");
                return false;
            }
            MarkValid(tbFolder);

            if (String.IsNullOrWhiteSpace(tbPricePercents.Text) || Regex.IsMatch(tbPricePercents.Text, "\\D"))
            {
                MarkInvalid(tbPricePercents, "Enter a valid number");
                return false;
            }
            MarkValid(tbPricePercents);

            return true;
        }

        private void worker_DoWork(object sender, DoWorkEventArgs e)
        {
            BackgroundWorker self = (BackgroundWorker)sender;
            Config cfg = (Config)e.Argument;

            CultureInfo ci = new CultureInfo("en-US");

            int totalCount = 1;
            int processedCount = 0;
            int progressValue = 0;

            List<Uri> products = new List<Uri>();

            // walk through categories
            Uri category = cfg.Uri;
            while(category != null)
            {
                string content = null;
                for (content = Web.GetContent(category); content == null; content = Web.GetContent(category))
                {
                    self.ReportProgress(progressValue, CONNECTION_ERROR);
                    Console.WriteLine("Failed {0}", category);
                    Thread.Sleep(SLEEPING_TIME);
                }

                Console.WriteLine("Read {0}", category);

                // get products
                MatchCollection mc = RE.Products.Matches(content);
                foreach (Match m in mc)
                {
                    Uri prod = new Uri(category, new Uri(m.Groups[1].Value, UriKind.Relative));
                    totalCount++;
                    products.Add(prod);
                }

                // check the next page
                Match np = RE.Page.Match(content);
                if (np.Success)
                {
                    category = new Uri(category, new Uri(np.Groups[1].Value, UriKind.Relative));
                }
                else
                    category = null;

                progressValue = (int)(100.0f / totalCount * processedCount);
                self.ReportProgress(progressValue, "Reading categories");
            }

            // walk through products
            ConcurrentBag<Photo> photoStorage = new ConcurrentBag<Photo>();
            Parallel.ForEach(products, product =>
            {

                string content = null;
                for (content = Web.GetContent(product); content == null; content = Web.GetContent(product))
                {
                    self.ReportProgress(progressValue, CONNECTION_ERROR);
                    Console.WriteLine("Failed {0}", product);
                    Thread.Sleep(SLEEPING_TIME);
                }

                Console.WriteLine("Read {0}", product);

                // check global suitability of the product:
                // skip this product in case when it is out of stock on Zappos
                if (!RE.ZapposOutOfStock.IsMatch(content))
                {
                    try
                    {
                        string brand = "";
                        string name = "";
                        float price = 0.0f;
                        float oldPrice = 0.0f;
                        string sku = "";

                        List<Photo> photoList = new List<Photo>();
                        List<string> sizeList = new List<string>();

                        Match brandname = RE.ZapposBrandName.Match(content);
                        if (brandname.Success)
                        {
                            brand = brandname.Groups[1].Value;
                            name = brandname.Groups[2].Value;
                            price = float.Parse(RE.ZapposPrice.Match(content).Groups[2].Value, ci.NumberFormat);
                            sku = RE.ZapposSku.Match(content).Groups[1].Value;
                            Match mop = RE.ZapposOldPrice.Match(content);
                            if (mop.Success)
                            {
                                oldPrice = float.Parse(mop.Groups[1].Value, ci.NumberFormat);
                            }


                            // get the Size's Id
                            Match mSI = RE.ZapposSizeId.Match(content);
                            if (mSI.Success)
                            {
                                string styleId = mSI.Groups[1].Value;
                                Regex reZapposSizeWrapper = RE.GetZapposSizeWrapper(styleId);
                                Match mSizeWrap = reZapposSizeWrapper.Match(content);
                                if (mSizeWrap.Success)
                                {
                                    MatchCollection mcSizeList = RE.ZapposSize.Matches(mSizeWrap.Groups[1].Value);
                                    foreach (Match mcs in mcSizeList)
                                        sizeList.Add(mcs.Groups[1].Value);
                                }
                                else
                                {
                                    Regex reZapposSingleSize = RE.GetZapposSingleSize(styleId);
                                    Match mZSS = reZapposSingleSize.Match(content);
                                    if (mZSS.Success)
                                        sizeList.Add(mZSS.Groups[1].Value);
                                    else
                                        throw new Exception("Cannot get product's size info: " + product.ToString());
                                }
                            }


                            // determine the style id to take an appropriate photo set
                            Match zsi = RE.ZapposStyleId.Match(content);
                            if (zsi.Success)
                            {
                                string style = zsi.Groups[1].Value;

                                // large images
                                HashSet<string> larges = new HashSet<string>();
                                Regex reZapposPhotosLarge = RE.GetZapposPhotosLarge(style);
                                MatchCollection mp = reZapposPhotosLarge.Matches(content);
                                foreach (Match m in mp)
                                {
                                    photoList.Add(new Photo(m.Groups[2].Value, PhotoSize.Large));
                                    larges.Add(m.Groups[1].Value);
                                }
                                // medium images
                                Regex reZapposPhotosMedium = RE.GetZapposPhotosMedium(style);
                                mp = reZapposPhotosMedium.Matches(content);
                                foreach (Match m in mp)
                                {
                                    if (!larges.Contains(m.Groups[1].Value))
                                        photoList.Add(new Photo(m.Groups[2].Value, PhotoSize.Medium));
                                }

                                // must be at least one picture
                                if (photoList.Count == 0)
                                    throw new Exception("No photos for " + product.ToString());
                            }
                            else
                                throw new Exception("No style id for " + product.ToString());

                        }
                        else
                        {
                            // may be we are at couture.zappos.com?
                            Match cbns = RE.CoutureBrandNameSku.Match(content);
                            if (!cbns.Success) throw new Exception("invalid source");
                            brand = cbns.Groups[1].Value;
                            name = cbns.Groups[2].Value;
                            sku = cbns.Groups[3].Value;
                            price = float.Parse(RE.CouturePrice.Match(content).Groups[1].Value, ci.NumberFormat);
                            Match mop = RE.CoutureOldPrice.Match(content);
                            if (mop.Success)
                            {
                                oldPrice = float.Parse(mop.Groups[1].Value, ci.NumberFormat);
                            }
                            Match mCPS = RE.CouturePhotoSource.Match(content);
                            if (mCPS.Success)
                            {
                                string cps_content = null;
                                Uri cps_photo_source = null;
                                cps_photo_source = new Uri(product, mCPS.Groups[1].Value);
                                cps_content = Web.GetContent(cps_photo_source);

                                for (cps_content = Web.GetContent(cps_photo_source); cps_content == null; cps_content = Web.GetContent(cps_photo_source))
                                {
                                    self.ReportProgress(progressValue, CONNECTION_ERROR);
                                    Console.WriteLine("Failed {0}", cps_photo_source);
                                    Thread.Sleep(SLEEPING_TIME);
                                }

                                Console.WriteLine("Read {0}", cps_photo_source);

                                MatchCollection cphotos = RE.CouturePhotos.Matches(cps_content);
                                foreach (Match mcp in cphotos)
                                    photoList.Add(new Photo(mcp.Groups[1].Value, PhotoSize.Large));

                            }
                            else
                                throw new Exception("no couture photo source: " + product);
                        }
                        // make photo objects
                        int newprice = (int)(0.5f + price + price / 100.0f * cfg.Percents);
                        string strPrice = newprice.ToString("C", ci);

                        string strOldPrice = String.Empty;
                        if (oldPrice > 0.0f)
                        {
                            int newOldPrice = (int)(0.5f + oldPrice + oldPrice / 100.0f * cfg.Percents);
                            strOldPrice = newOldPrice.ToString("C", ci);
                        }
                        foreach (Photo pObj in photoList.Take(cfg.PhotosLimit))
                        {
                            pObj.Brand = brand;
                            pObj.Name = name;
                            pObj.Price = strPrice;
                            pObj.OldPrice = strOldPrice;
                            pObj.Sku = sku;
                            pObj.Sizes.AddRange(sizeList);
                            photoStorage.Add(pObj);
                            Interlocked.Increment(ref totalCount);
                        }
                    }
                    catch (Exception ex)
                    {
                        // an error happened
                        Console.WriteLine(ex.Message);
                        throw new Exception(ex.Message);
                    }
                }

                
                Interlocked.Increment(ref processedCount);
                progressValue = (int)(100.0f / totalCount * processedCount);
                self.ReportProgress(progressValue, "Reading products");

            });


            // in case when folder separation is needed, we create those folders
            if (cfg.DirectoryLimit > 0)
            {
                int numberOfDirectories = (int)Math.Ceiling((double)((float)photoStorage.Count / cfg.DirectoryLimit));
                for (int dn = 0; dn < numberOfDirectories; dn++)
                {
                    string subdir = (dn + 1).ToString("D4");
                    string dirPath = Path.Combine(cfg.Folder, subdir);
                    if (!Directory.Exists(dirPath)) Directory.CreateDirectory(dirPath);
                    var part = photoStorage.Skip(cfg.DirectoryLimit * dn).Take(cfg.DirectoryLimit);
                    foreach (Photo p in part)
                        p.SubDirectory = subdir;
                }
            }

            // download and update photos
            var unprocessedPhotos = photoStorage.Where(p => p.Status == PhotoStatus.New || p.Status == PhotoStatus.Downloaded).ToArray();
            while (unprocessedPhotos.Length > 0)
            {
                Parallel.ForEach(unprocessedPhotos, photo =>
                {
                    // download or convert
                    string folder = cfg.Folder;
                    if (!String.IsNullOrEmpty(photo.SubDirectory))
                        folder = Path.Combine(cfg.Folder, photo.SubDirectory);
                    string orgname = Path.Combine(folder, "org." + photo.FileName);
                    string destname = Path.Combine(folder, photo.FileName);

                    if (photo.Status == PhotoStatus.New)
                    {
                        // try download
                        DownloadResult result = Web.GetFile(photo.Uri, orgname);
                        switch (result)
                        {
                            case DownloadResult.NotFound:
                                // just skip the picture
                                photo.Status = PhotoStatus.Rejected;
                                break;
                            case DownloadResult.Error:
                                // try again
                                self.ReportProgress(progressValue, CONNECTION_ERROR);
                                Console.WriteLine("Failed {0}", photo.Uri);
                                Thread.Sleep(SLEEPING_TIME);
                                break;
                            case DownloadResult.Ok:
                                photo.Status = PhotoStatus.Downloaded;
                                Console.WriteLine("Read {0}", photo.Uri);
                                break;
                        }
                    }

                    if (photo.Status == PhotoStatus.Downloaded)
                    {
                        // try convert
                        if (Painter.ApplyPhoto(orgname, photo, cfg, destname))
                        {
                            photo.Status = PhotoStatus.Processed;
                            progressValue = (int)(100.0f / totalCount * Interlocked.Increment(ref processedCount));
                            try
                            {
                                // delete the original file
                                File.Delete(orgname);
                            }
                            catch (Exception) { }

                            self.ReportProgress(progressValue, "Downloading pictures");
                        }
                        else
                        {
                            self.ReportProgress(progressValue, CONVERSION_ERROR);
                        }
                    }


                });


                unprocessedPhotos = photoStorage.Where(p => p.Status == PhotoStatus.New || p.Status == PhotoStatus.Downloaded).ToArray();
            }

            e.Result = String.Format("Downloaded {0} pictures from {1} products",
                photoStorage.Count(p => p.Status == PhotoStatus.Processed), 
                products.Count);

        }

        private void worker_RunWorkerCompleted(object sender, RunWorkerCompletedEventArgs e)
        {
            DateTime finished = DateTime.Now;
            SetControlState(true);
            lblProgressMessage.Text = string.Empty;

            if (e.Error != null)
                MessageBox.Show(e.Error.Message, "An error has occured");
            if (e.Result != null) 
                MessageBox.Show(String.Format("{0} ({1})", e.Result.ToString(), finished-started), "Done");

            tbFolder.Text = string.Empty;
            tbUrl.Text = string.Empty;
            tbUrl.Focus();
        }

        private void worker_ProgressChanged(object sender, ProgressChangedEventArgs e)
        {
            
            progress.Value = e.ProgressPercentage;
            lblProgressMessage.Text = (string)e.UserState;
        }
    }
}
