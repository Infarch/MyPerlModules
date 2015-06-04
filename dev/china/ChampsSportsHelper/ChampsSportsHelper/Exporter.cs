using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

using System.IO;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Drawing.Imaging;

using FileHelpers;

namespace ChampsSportsHelper
{
    class Exporter
    {

        public static Task<string> ExportModelsAsync(
            IEnumerable<ProductModel> models, 
            string mainDir, 
            IEnumerable<string> additionalDirs, 
            float priceMultiple, 
            float priceAdd, 
            IProgress<int> tracker)
        {

            // prepare directories
            string exportFolderName = DateTime.Now.ToString("dd-MM-yyyy HH-mm-ss");
            string exportPath = Path.Combine(Constants.ExportsDir, exportFolderName);
            if (!Directory.Exists(exportPath))
                Directory.CreateDirectory(exportPath);
            string imagesPath = Path.Combine(exportPath, "images");
            if (!Directory.Exists(imagesPath))
                Directory.CreateDirectory(imagesPath);

            return Task.Factory.StartNew<string>(() =>
            {
                
                int cnt = 1;
                List<ExportItem> exports = new List<ExportItem>();

                if (!String.IsNullOrEmpty(mainDir))
                {
                    exports.Add(new ExportItem()
                    {
                        Name = mainDir
                    });
                }

                foreach (ProductModel model in models)
                {
                    IEnumerable<string> sizes = model.AllSizes.Select(a => { return a.Trim(); });
                    string sizeStr = BuildSize(sizes);
                    foreach (ProductStyle style in model.Styles)
                    {
                        ExportItem item = CreateExportItem(model, style, additionalDirs, imagesPath, priceMultiple, priceAdd);
                        item.Size = sizeStr;
                        exports.Add(item);
                    }
                    tracker.Report(cnt++);
                }

                // write to file
                FileHelperEngine<ExportItem> engine = new FileHelperEngine<ExportItem>(Encoding.UTF8);
                engine.HeaderText = ExportItem.HEADERS;
                engine.WriteFile(Path.Combine(exportPath, "products.csv"), exports);

                // delete all downloaded files
                DirectoryInfo di = new DirectoryInfo(Constants.DownloadsDir);
                foreach (var d in di.GetFiles())
                {
                    d.Delete();
                }

                return exportPath;
            });
        }

        private static ExportItem CreateExportItem(
            ProductModel model, 
            ProductStyle style, 
            IEnumerable<string> additionalDirs, 
            string imagesPath, 
            float priceMultiple, 
            float priceAdd)
        {
            ExportItem prod = new ExportItem();
            prod.Sku = style.Sku;
            prod.Name = model.Name;
            prod.Description = model.Description;

            prod.Price = BuildPrice(style.DiscountPrice, priceMultiple, priceAdd);
            if (style.DiscountPrice < style.Price)
            {
                prod.OldPrice = BuildPrice(style.Price, priceMultiple, priceAdd);
            }

            // we use a single size list for all styles in a model, so I create the list in the caller function
            //prod.Size = BuildSize(style.Sizes.ToArray());

            prod.MoreCategories = string.Join<string>(",", additionalDirs);
            prod.SizeChartType = model.GenderAge;

            int imageCount = 0;
            foreach (ProductImage pi in style.Images.FindAll(p => p.Downloaded))
            {
                string pathSource = Path.Combine(Constants.DownloadsDir, pi.Name + ".jpg");
                if (File.Exists(pathSource))
                {
                    if (imageCount == 10) break; // up to 10 images

                    ThumbnailInfo tiInfo = new ThumbnailInfo()
                    {
                        Name = pi.Name + "_info.jpg",
                        Width = 300,
                        Height = 300
                    };
                    ThumbnailInfo tiThumbnail = new ThumbnailInfo()
                    {
                        Name = pi.Name + "_th.jpg",
                        Width = 150,
                        Height = 150
                    };
                    ThumbnailInfo tiLarge = new ThumbnailInfo()
                    {
                        Name = pi.Name + "_large.jpg",
                        Width = 1000,
                        Height = 1000
                    };
                    ThumbnailInfo[] thumbnails = new ThumbnailInfo[] { tiInfo, tiThumbnail, tiLarge };

                    if (MakeJpegThumbnails(pathSource, imagesPath, thumbnails))
                    {
                        prod.SetPhoto(imageCount++, tiInfo.Name + "," + tiThumbnail.Name + "," + tiLarge.Name);
                    }
                }
            }

            return prod;
        }

        private static string BuildSize(IEnumerable<string> sizes)
        {
            if (sizes.Count() == 0) return "";
            // {,07.0,07.5,06.5}
            return "{," + String.Join(",", sizes) + "}";
        }

        private static string BuildPrice(float price, float multiple, float add)
        {
            float result = price * multiple + add;
            int p1 = (int)Math.Truncate(result);
            result = (result - p1) * 100;
            int p2 = (int)Math.Truncate(result);
            return String.Format("{0}.{1}", p1, p2);
        }

        /// <summary>
        /// Returns true if success
        /// </summary>
        /// <param name="sourceFile"></param>
        /// <param name="destPath"></param>
        /// <param name="thumbnails"></param>
        /// <returns></returns>
        private static bool MakeJpegThumbnails(string sourceFile, string destPath, IEnumerable<ThumbnailInfo> thumbnails)
        {
            return MakeThumbnails(sourceFile, destPath, thumbnails, ImageFormat.Jpeg);
        }


        /// <summary>
        /// Returns true if success
        /// </summary>
        /// <param name="sourceFile"></param>
        /// <param name="destPath"></param>
        /// <param name="thumbnails"></param>
        /// <param name="format"></param>
        /// <returns></returns>
        private static bool MakeThumbnails(string sourceFile, string destPath, IEnumerable<ThumbnailInfo> thumbnails, ImageFormat format)
        {
            bool ok = false;
            try
            {
                using (Image img = Image.FromFile(sourceFile))
                {
                    foreach (ThumbnailInfo ti in thumbnails)
                    {
                        string destFile = Path.Combine(destPath, ti.Name);
                        using (Image b = Resize(img, ti.Width, ti.Height))
                            b.Save(destFile, format);
                    }
                }
                ok = true;
            }
            catch { }
            return ok;
        }

        private static Image Resize(Image srcImg, int width, int height)
        {
            Bitmap b = new Bitmap(width, height);
            using (Graphics g = Graphics.FromImage((Image)b))
            {
                g.SmoothingMode = SmoothingMode.AntiAlias;
                g.InterpolationMode = InterpolationMode.HighQualityBicubic;
                g.PixelOffsetMode = PixelOffsetMode.HighQuality;
                g.DrawImage(srcImg, 0, 0, width, height);

                return (Image)b;
            }

        }

    }
}
