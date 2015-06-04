#define xDebug


using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.Linq;
using System.Text;
using System.Text.RegularExpressions;
using System.Threading;
using System.Windows.Forms;
using System.IO;
using System.Net;

using PicassaLib;




namespace PicassaDownloader
{
    public partial class Form1 : Form
    {
        #region Variables

        /// <summary>
        /// Url of the current album
        /// </summary>
        String currentUrl;

        /// <summary>
        /// Enumeration of all possible application states.
        /// </summary>
        private enum State { New, Download, PrepareOutput, Output, Closing };

        /// <summary>
        /// State of the application
        /// </summary>
        private State currentState;

        /// <summary>
        /// WebClient performs http requests
        /// </summary>
        private WebClient webClient;

        /// <summary>
        /// List of the Photo objects representing the current album
        /// </summary>
        private List<Photo> photos;

        /// <summary>
        /// Output directory for the 'output.csv' file
        /// </summary>
        private String target = "output";

        /// <summary>
        /// Output directory for the products pictures
        /// </summary>
        private String targetPP = "output\\products_pictures";

        /// <summary>
        /// Group counter. Each group represents seevral photos to be joined into a single product.
        /// </summary>
        private int groupCounter;

        /// <summary>
        /// Temporary directory for downloaded images.
        /// </summary>
        private String Storage = "images";

        #endregion

        #region FormMethods

        public Form1()
        {
            InitializeComponent();
        }

        private void Form1_Load(object sender, EventArgs e)
        {
            if (!Directory.Exists(Storage))
            {
                Directory.CreateDirectory(Storage);
            }
            setState(State.New);
            webClient = new WebClient();
            webClient.Encoding = System.Text.Encoding.UTF8;

        }

        private void Form1_FormClosing(object sender, FormClosingEventArgs e)
        {
            setState(State.Closing);

            downloadWorker.CancelAsync();
            exportWorker.CancelAsync();

            // clean up the cache directory
            TimeSpan delta = new TimeSpan(7, 0, 0, 0);
            DateTime dd = DateTime.Now.Subtract(delta);

            DirectoryInfo di = new DirectoryInfo(Storage);
            foreach (System.IO.FileInfo file in di.GetFiles())
            {

            }

        }

        #endregion

        private void setState(State state)
        {
            switch (state)
            {
                case State.New:
#if(!Debug)
                    tbUrl.Text = "";
#endif
                    photos = new List<Photo>();
                    setPanelState(pnNavigation, true);
                    setPanelState(pnToolbar, false);
                    slStatus.Text = "Ready to work";
                    spProgress.Value = 0;
                    spProgress.Visible = false;
                    flowPanel.Controls.Clear();
                    break;
                case State.Download:
                    setPanelState(pnNavigation, false);
                    setPanelState(pnToolbar, false);
                    slStatus.Text = "Downloading...";
                    spProgress.Visible = true;
                    break;
                case State.PrepareOutput:
                    groupCounter = 1;
                    setPanelState(pnNavigation, true);
                    setPanelState(pnToolbar, true);
                    slStatus.Text = "Prepare export";
                    spProgress.Visible = false;
                    showThumbnails();
                    break;
                case State.Output:
                    setPanelState(pnNavigation, false);
                    setPanelState(pnToolbar, false);
                    slStatus.Text = "Exporting...";
                    spProgress.Value = 0;
                    spProgress.Visible = true;
                    break;
                case State.Closing:
                    slStatus.Text = "Closing...";
                    DoClose();
                    break;
                default:
                    MessageBox.Show("Bad state");
                    break;
            }
            currentState = state;
        }

        private void DoClose()
        {
            downloadWorker.CancelAsync();
            exportWorker.CancelAsync();

#if (!Debug)

            // clean up the cache directory
            TimeSpan delta = new TimeSpan(7, 0, 0, 0);
            DateTime dd = DateTime.Now.Subtract(delta);

            DirectoryInfo di = new DirectoryInfo(Storage);
            foreach (System.IO.FileInfo file in di.GetFiles())
            {
                if (file.LastWriteTime < dd)
                {
                    try
                    {
                        file.Delete();
                    }
                    catch { }
                }
            }
#endif
        }

        private void btnGo_Click(object sender, EventArgs e)
        {
            if (tbUrl.Text == "") return;
            if (currentState == State.PrepareOutput)
            {
                if (!Confirm("All the current album's data will be lost. Continue?"))
                {
                    tbUrl.Text = currentUrl;
                    return;
                }
                // remove old data
                photos.Clear();
                flowPanel.Controls.Clear();
                spProgress.Value = 0;
            }
            currentUrl = tbUrl.Text;
            setState(State.Download);
            Application.DoEvents();
            try
            {
                String content = webClient.DownloadString(currentUrl);
                extrachPhotos(content);
                // start downloader
                spProgress.Maximum = photos.Count;
                downloadWorker.RunWorkerAsync(photos);
            }
            catch (Exception exc)
            {
                MessageBox.Show(exc.Message, "Error reading album");
                setState(State.New);
            }
            
        }

        private void btnExport_Click(object sender, EventArgs e)
        {
            if (Selection().Count > 0)
            {
                MessageBox.Show("You have several photos checked. Please select any accessible action or just untick those photos");
                return;
            }

            if (Confirm("Are you ready for export?"))
            {
                setState(State.Output);

                if (Directory.Exists(target))
                    Empty(target);
                else
                    Directory.CreateDirectory(target);

                if (Directory.Exists(targetPP))
                    Empty(targetPP);
                else
                    Directory.CreateDirectory(targetPP);

                exportWorker.RunWorkerAsync();
            }
        }

        private void sendToOutput(StringBuilder sb, CSV csv, Product prod, String code, int cc)
        {
            try
            {
                // prepare product data for CSV
                Dictionary<String, String> pdata = new Dictionary<String, String>();
                String description = Regex.Replace(prod.Description, "\r|\n|\t", " ");
                description = Regex.Replace(description, "\\s{2,}", " ");
                description = Regex.Replace(description, "\"", "\"\"");

                String[] dparts = description.Split(" ".ToCharArray());
                int limit = dparts.Length < 5 ? dparts.Length : 5;
                String name = String.Join(" ", dparts, 0, limit);

                pdata.Add("description", description);
                pdata.Add("name", name);
                pdata.Add("code", code+cc);
                
                // process pictures
                String[] pics = prod.getPhotoNames();

                String fullcode = "ispc_" + code + cc;

                for (int i = 0; i < pics.Length; i++)
                {
                    Image img = Image.FromFile(Path.Combine(Storage, pics[i]));

                    // small thumbnail
                    String n1 = fullcode + "_" + i + "_th.jpg";
                    ImageConvert.MakeSmallThumbnail(img, Path.Combine(targetPP, n1));

                    // large thumbnail
                    String n2 = fullcode + "_" + i + ".jpg";
                    ImageConvert.MakeLargeThumbnail(img, Path.Combine(targetPP, n2));

                    // save original image
                    String n3 = fullcode + "_" + i + "_enl.jpg";
                    img.Save(Path.Combine(targetPP, n3));

                    pdata.Add("picture_" + (i + 1), n2 + "," + n1 + "," + n3);
                }

                csv.AddRow(sb, pdata);
            }
            catch(Exception ex)
            {
                MessageBox.Show(ex.Message, "Error");
            }

        }

        #region Auxiliary
        
        private void tbStartNumber_Validating(object sender, CancelEventArgs e)
        {
            TextBox box = sender as TextBox;
            try
            {
                int number = int.Parse(box.Text);
            }
            catch (FormatException)
            {
                e.Cancel = true;
                MessageBox.Show("You need to enter an integer");
            }
        }

        private void tbCode_Validating(object sender, CancelEventArgs e)
        {
            TextBox box = sender as TextBox;
            if (box.Text == "")
            {
                e.Cancel = true;
                MessageBox.Show("This field must not be empty");
            }
        }

        private void extrachPhotos(string content)
        {
            String pattern = "\"media\":{\"content\":\\[{\"url\":\"([^\"]+)\".*?\\],\"description\":\"([^\"]*)\"";

            MatchCollection matches = Regex.Matches(content, pattern, RegexOptions.IgnoreCase);

            for (int i = 0; i < matches.Count; i++)
            {
                Photo p = new Photo(matches[i].Groups[1].Value, matches[i].Groups[2].Value);
                photos.Add(p);
            }

        }

        private static void Empty(String path)
        {
            DirectoryInfo di = new DirectoryInfo(path);
            foreach (System.IO.FileInfo file in di.GetFiles()) file.Delete();
            //foreach (System.IO.DirectoryInfo subDirectory in directory.GetDirectories()) directory.Delete(true);
        }

        private void setPanelState(Panel pan, Boolean enabled)
        {
            foreach (Control c in pan.Controls)
            {
                c.Enabled = enabled;
            }
        }

        private void showThumbnails()
        {
            int thWidth = 125;
            int thHeight = 125;
            int picHeight = thHeight - 20;

            foreach (Photo p in photos)
            {
                Panel pn = new Panel();
                pn.Width = thHeight;
                pn.Height = thWidth;
                pn.Margin = new Padding(5);
                pn.BorderStyle = BorderStyle.Fixed3D;
                pn.BackColor = SystemColors.Info;

                PictureBox pic = new PictureBox();
                pic.ImageLocation = Path.Combine(Storage, p.Name);
                pic.Height = picHeight;
                pic.Dock = DockStyle.Top;
                pic.SizeMode = PictureBoxSizeMode.Zoom;
                pn.Controls.Add(pic);

                ToolTip tip = new ToolTip();
                tip.SetToolTip(pic, p.Description);

                CheckBox cb = p.CheckBox;
                cb.Top = thHeight - cb.Height;
                cb.Left = 2;
                pn.Controls.Add(cb);

                // container also switches selection


                EventHandler del = (obj, ev) => cb.Checked = !cb.Checked;
                pn.Click += del;
                pic.Click += del;

                flowPanel.Controls.Add(pn);

                Application.DoEvents();
            }
        }

        private Boolean Confirm(String message)
        {
            return MessageBox.Show(message, "Confirm", MessageBoxButtons.YesNo) == DialogResult.Yes;
        }
        
        #endregion

        #region SelectionHandlers

        private List<Photo> Selection()
        {
            // query for all selected photos
            var query =
                from ph in photos
                where ph.Checked
                select ph;
            List<Photo> plist = new List<Photo>();

            foreach (var p in query)
            {
                plist.Add(p);
            }

            return plist;
        }

        private void btnUngroup_Click(object sender, EventArgs e)
        {
            foreach (Photo p in Selection())
            {
                p.GroupNumber = 0;
                p.Excluded = false;
                p.Checked = false;
                p.Hint = "";
            }
        }

        private void btnNewGroup_Click(object sender, EventArgs e)
        {
            List<Photo> plist = Selection();
            if (plist.Count > 0)
            {
                foreach (Photo p in plist)
                {
                    p.GroupNumber = groupCounter;
                    p.Excluded = false;
                    p.Checked = false;
                    p.Hint = "#" + groupCounter;
                }
                groupCounter++;
            }
            else
            {
                MessageBox.Show("Please tick at least one object");
            }

        }

        private void btnExclude_Click(object sender, EventArgs e)
        {
            List<Photo> plist = Selection();
            if (plist.Count > 0)
            {
                foreach (Photo p in plist)
                {
                    p.Excluded = true;
                    p.Checked = false;
                    p.Hint = "Excluded";
                }
                groupCounter++;
            }
            else
            {
                MessageBox.Show("Please tick at least one object");
            }
        }

        #endregion

        #region Backgroung

        private void downloadWorker_DoWork(object sender, DoWorkEventArgs e)
        {
            BackgroundWorker worker = sender as BackgroundWorker;
            int c = 1;
            foreach (Photo p in photos)
            {
                if (worker.CancellationPending)
                {
                    e.Cancel = true;
                    break;
                }
                else
                {
                    // download
                    String filename = Path.Combine(Storage, p.Name);
                    if (!File.Exists(filename))
                    {
                        Boolean ok = false;
                        while (!ok && !worker.CancellationPending)
                        {
                            try
                            {
                                webClient.DownloadFile(p.Url, filename);
                                ok = true;
                            }
                            catch (Exception)
                            { }

                        }
                    }
                    worker.ReportProgress(c++);

                }
            }

        }

        private void downloadWorker_RunWorkerCompleted(object sender, RunWorkerCompletedEventArgs e)
        {
            if (e.Error != null)
            {
                MessageBox.Show(e.Error.Message);
            }
            else if (!e.Cancelled)
            {
                setState(State.PrepareOutput);
            }
        }

        private void downloadWorker_ProgressChanged(object sender, ProgressChangedEventArgs e)
        {
            spProgress.Value = e.ProgressPercentage;
        }

        private void exportWorker_DoWork(object sender, DoWorkEventArgs e)
        {
            BackgroundWorker worker = sender as BackgroundWorker;

            int cc = int.Parse(tbStartNumber.Text);

            int progress = 0;
            var query =
                from p in photos
                where !p.Excluded
                group p by p.GroupNumber into g
                select new { GroupNumber = g.Key, Photos = g };

            StringBuilder sb = new StringBuilder();
            CSV csv = new CSV();
            csv.MakeHeader(sb);

            foreach (var group in query)
            {
                if (worker.CancellationPending)
                {
                    e.Cancel = true;
                    break;
                }
                else
                {
                    if (group.GroupNumber > 0)
                    {
                        // a group
                        Product prod = null;
                        foreach (var ph in group.Photos)
                        {
                            if (prod == null)
                            {
                                prod = new Product(ph);
                            }
                            else
                            {
                                prod.addPhoto(ph);
                            }
                            progress++;
                        }
                        sendToOutput(sb, csv, prod, tbCode.Text, cc++);
                        worker.ReportProgress(progress);
                    }
                    else
                    {
                        // group 0 - means photos outside groups
                        foreach (var ph in group.Photos)
                        {
                            Product prod = new Product(ph);
                            sendToOutput(sb, csv, prod, tbCode.Text, cc++);
                            progress++;
                            worker.ReportProgress(progress);
                        }
                    }
                }

            }

            // make cp1251 string
            String output = sb.ToString();

            Encoding te = Encoding.GetEncoding("windows-1251");
            Encoding se = Encoding.Unicode;

            byte[] sourceBytes = se.GetBytes(output);
            byte[] destBytes = Encoding.Convert(se, te, sourceBytes);

            char[] destChars = new char[te.GetCharCount(destBytes, 0, destBytes.Length)];
            te.GetChars(destBytes, 0, destBytes.Length, destChars, 0);
            output = new String(destChars);

            // remove '?'
            output = Regex.Replace(output, "\\?", "");

            String outfile = Path.Combine(target, "output.csv");
            TextWriter tw = new StreamWriter(outfile, false, te);
            tw.Write(output);
            tw.Close();

            e.Result = cc;
        }

        private void exportWorker_RunWorkerCompleted(object sender, RunWorkerCompletedEventArgs e)
        {
            if (e.Error != null)
            {
                MessageBox.Show(e.Error.Message);
            }
            else if (!e.Cancelled)
            {
                tbStartNumber.Text = e.Result.ToString();
                setState(State.New);
            }
        }

        private void exportWorker_ProgressChanged(object sender, ProgressChangedEventArgs e)
        {
            spProgress.Value = e.ProgressPercentage;
        }

        #endregion
    }
}
