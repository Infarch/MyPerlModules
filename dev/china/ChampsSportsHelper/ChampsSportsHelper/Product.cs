using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.IO;

namespace ChampsSportsHelper
{
    /// <summary>
    /// A newe class, designed for processing given Model+Sku pairs, instead of all available Sku at once
    /// </summary>
    class Product
    {
        public enum ProcessStatus { New, Processed, Failed };

        public ProcessStatus Status { get; private set; }

        public int ModelNumber { get; set; }
        public string Sku { get; set; }
        public string Name { get; set; }
        public string Description { get; set; }
        public string Brand { get; set; }
        public string GenderAge { get; set; }
        public string Width { get; set; }
        public float Price { get; set; }
        public float DiscountPrice { get; set; }

        public List<String> Sizes { get; private set; }
        public List<ProductImage> Images { get; private set; }

        public Product(int modelNumber, string sku)
        {
            ModelNumber = modelNumber;
            Sku = sku;
            Status = ProcessStatus.New;
            Sizes = new List<string>();
            Images = new List<ProductImage>();
        }

        public void Process()
        {
            // download a the main page
            string url = String.Format("http://www.champssports.com/product/model:{0}/sku:{1}/", ModelNumber, Sku);
            Console.WriteLine("Downloading a product: {0}" + url);
            string mainPage = Web.DownloadString(url, 5);
            if (String.IsNullOrEmpty(mainPage))
                throw new Exception("Empty page: " + url);

            string rawModel = RX.ExtractModelInfo(mainPage);
            string rawStyles = RX.ExtractStylesInfo(mainPage);

            JX.PopulateProduct(this, rawModel, rawStyles);

            string backupImage = RX.ExtractMetaImage(mainPage);
            GetImages(backupImage);

            Status = ProcessStatus.Processed;
        }

        private void GetImages(string usIfNoImages)
        {
            // request images
            string jsonUrl = String.Format("http://images.champssports.com/is/image/EBFL/{0}?req=imageset,json", Sku);
            string result = Web.DownloadString(jsonUrl, 3);
            if(!String.IsNullOrEmpty(result))
            {
                var images = RX.ExtractImages(result);
                int count = 0;
                foreach (string image in images)
                {
                    Images.Add(
                        new ProductImage(
                            String.Format("{0}_{1}_{2}", ModelNumber, Sku, count++),
                            String.Format("http://images.champssports.com/is/image//{0}?hei=1500&wid=1500", image)
                        )
                    );
                }
            }

            // no images, try to apply the Plan B
            if (Images.Count == 0 && !String.IsNullOrEmpty(usIfNoImages))
            {
                Images.Add(
                    new ProductImage(
                        String.Format("{0}_{1}_{2}", ModelNumber, Sku, 0),
                        usIfNoImages
                    )
                );
            }

            // download all these images
            Parallel.ForEach(Images, image =>
            {
                string path = Path.Combine(Constants.DownloadsDir, image.Name + ".jpg");
                if (!File.Exists(path))
                    Web.DownloadFile(image.Url, path, 5);
            });
        }
    }
}
