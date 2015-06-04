using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
//using System.Text.RegularExpressions;
using System.IO;

using Newtonsoft.Json.Linq;

namespace ChampsSportsHelper
{
    class ProductStyle
    {
        const int IDX_STYLE_ATTRS = 0;
        const int IDX_STYLE_PRICE = 5;
        const int IDX_STYLE_DISCOUNT_PRICE = 6;
        const int IDX_STYLE_SIZES = 7;

        bool keepDownloads;

        public string Width { get; private set; }
        public string Sku { get; private set; }
        public float Price { get; set; }
        public float DiscountPrice { get; set; }
        public List<string> Sizes { get; private set; }
        public List<ProductImage> Images { get; private set; }
        public bool IsDone { get; set; }

        private JArray raw;

        public ProductStyle(string sku, JArray rawStyle, bool keepDownloads = true)
        {
            raw = rawStyle;
            Sku = sku;
            IsDone = false;
            Sizes = new List<string>();
            Images = new List<ProductImage>();
            this.keepDownloads = keepDownloads;
        }

        public void Process()
        {
            string styleAttrs = raw[IDX_STYLE_ATTRS].ToString();

            Width = RX.ExtractWidth(raw[IDX_STYLE_ATTRS].ToString());

            Price = (float)raw[IDX_STYLE_PRICE];
            DiscountPrice = (float)raw[IDX_STYLE_DISCOUNT_PRICE];

            JArray rawSizes = (JArray)raw[IDX_STYLE_SIZES];
            for (int i = 0; i < rawSizes.Count; i++)
            {
                JArray jSize = (JArray)rawSizes[i];
                string size = jSize[0].ToString().Trim();
                Sizes.Add(size);
            }

            TakeImages();

            IsDone = true;

        }

        private void TakeImages()
        {
            Console.WriteLine("Reading images: {0}", Sku);

            // request images
            string jsonUrl = String.Format("http://images.champssports.com/is/image/EBFL/{0}?req=imageset,json", Sku);
            string result = Web.DownloadString(jsonUrl, 3);
            if (!String.IsNullOrEmpty(result))
            {
                var images = RX.ExtractImages(result);
                int count = 0;
                foreach (string image in images)
                {
                    Images.Add(
                        new ProductImage(
                            String.Format("{0}_{1}", Sku, count++),
                            String.Format("http://images.champssports.com/is/image//{0}?hei=1500&wid=1500", image)
                        )
                    );
                }
            }

            if (Images.Count == 0)
            {
                // There are no images for the products. But we could try to get at least one 500x500...
                // First of all, get the product as a separate web page.
                string xPage = Web.DownloadString(String.Format("http://www.champssports.com/product/model:0/sku:{0}", Sku), 2);
                if (!String.IsNullOrEmpty(xPage))
                {
                    string metaImg = RX.ExtractMetaImage(xPage);
                    if (!String.IsNullOrEmpty(metaImg))
                        Images.Add(new ProductImage(String.Format("{0}_{1}", Sku, 0), metaImg));
                }
            }

            // download all these images
            Parallel.ForEach(Images, image =>
            {
                string path = Path.Combine(Constants.DownloadsDir, image.Name + ".jpg");
                if (!keepDownloads || !File.Exists(path))
                   image.Downloaded = Web.DownloadFile(image.Url, path, 10);
            });

            Console.WriteLine("{0} : all images have been downloaded", Sku);
        }

    }
}
