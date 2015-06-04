using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

using Newtonsoft.Json;
using Newtonsoft.Json.Linq;

namespace ChampsSportsHelper
{
    /// <summary>
    /// Implements various operations need Json parsing
    /// </summary>
    class JX
    {
        private const int IDX_STYLE_ATTRS = 0;
        private const int IDX_STYLE_PRICE = 5;
        private const int IDX_STYLE_DISCOUNT_PRICE = 6;
        private const int IDX_STYLE_SIZES = 7;

        /// <summary>
        /// An auxiliary class for parsing model info
        /// </summary>
        class JsonModel
        {
            public string BRAND { get; set; }
            public string NM { get; set; }
            public string GENDER_AGE { get; set; }
            public string INET_COPY { get; set; }
        }

        /// <summary>
        /// Populates a given instance of Product by data extracted from Json strings
        /// </summary>
        /// <param name="product"></param>
        /// <param name="model"></param>
        /// <param name="styles"></param>
        public static void PopulateProduct(Product product, string model, string styles)
        {
            JsonModel jsModel = JsonConvert.DeserializeObject<JsonModel>(model);

            Dictionary<string, JArray> rawStyles =
                JsonConvert.DeserializeObject<Dictionary<string, JArray>>(styles);

            product.Name = jsModel.NM;
            product.Brand = jsModel.BRAND;
            product.GenderAge = jsModel.GENDER_AGE;
            product.Description = jsModel.INET_COPY;

            JArray jsStyle = rawStyles[product.Sku];
            product.Width = RX.ExtractWidth(jsStyle[IDX_STYLE_ATTRS].ToString());

            product.Price = (float)jsStyle[IDX_STYLE_PRICE];
            product.DiscountPrice = (float)jsStyle[IDX_STYLE_DISCOUNT_PRICE];

            JArray jsSizes = (JArray)jsStyle[IDX_STYLE_SIZES];
            for (int i = 0; i < jsSizes.Count; i++)
            {
                JArray jSize = (JArray)jsSizes[i];
                string size = jSize[0].ToString().Trim();
                product.Sizes.Add(size);
            }





        }

    }
}
