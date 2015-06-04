using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

using Newtonsoft.Json;
using Newtonsoft.Json.Linq;

namespace ChampsSportsHelper
{
    class ProductModel
    {

        public enum ModelStatus { New, Processed, Failed };

        JsModel jsModel;
        string initialSku;
        bool keepDownloads;

        public int Number { get; private set; }

        public string Name { get { return jsModel.NM; } }
        public string Description { get { return jsModel.INET_COPY; } }
        public string Brand { get { return jsModel.BRAND; } }
        public string GenderAge { get { return jsModel.GENDER_AGE; } }
        public IEnumerable<string> AllSizes { get { return jsModel.AVAILABLE_SIZES; } }
        public ModelStatus Status { get; set; }
        public List<ProductStyle> Styles { get; set; }


        public ProductModel(int number, string initialSku, bool keepDownloads = true)
        {
            Number = number;
            jsModel = new JsModel();
            this.initialSku = initialSku;
            Status = ModelStatus.New;
            Styles = new List<ProductStyle>();
            this.keepDownloads = keepDownloads;
        }

        public void Process()
        {
            // download a the main page
            string url = String.Format("http://www.champssports.com/product/model:{0}/sku:{1}/", Number, initialSku);
            Console.WriteLine("Downloading a model: " + url);
            string mainPage = Web.DownloadString(url, 5);
            if (String.IsNullOrEmpty(mainPage))
            {
                Status = ModelStatus.Failed;
                return;
            }
            Console.WriteLine("Parsing data...");

            string rawModel = RX.ExtractModelInfo(mainPage);
            string rawStyles = RX.ExtractStylesInfo(mainPage);
            
            jsModel = JsonConvert.DeserializeObject<JsModel>(rawModel);

            Dictionary<string, JArray> jStyles =
                JsonConvert.DeserializeObject<Dictionary<string, JArray>>(rawStyles);

            foreach (string sku in jsModel.ALLSKUS)
            {
                JArray rawStyle = jStyles[sku];
                ProductStyle stl = new ProductStyle(sku, rawStyle);
                Styles.Add(stl);
            }

            Parallel.ForEach(Styles, _ =>
            {
                _.Process();
            });

            Status = ModelStatus.Processed;
        }
    }
}
