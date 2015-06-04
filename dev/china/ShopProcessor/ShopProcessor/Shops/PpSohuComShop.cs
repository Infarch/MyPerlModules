using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Windows.Forms;
using System.Text.RegularExpressions;

namespace ShopProcessor.Shops
{
    class PpSohuComShop : Shop
    {
        public override string GetDomain()
        {
            return "pp.sohu.com";
        }

        public override List<Product> ExtractProducts(System.Windows.Forms.HtmlDocument document)
        {
            List<Product> products = new List<Product>();

            HtmlElementCollection tt = document.GetElementsByTagName("head");
            if (tt.Count == 1)
            {
                HtmlElement title = tt[0];
                //title.in
                String pattern = "\\{.*?\"middle\":\"([^\"]+)\".*?\"description\":\"([^\"]*)\"";
                MatchCollection matches = Regex.Matches(title.InnerHtml, pattern, RegexOptions.IgnoreCase);
                for (int i = 0; i < matches.Count; i++)
                {
                    Product prod = new Product();
                    prod.Name = matches[i].Groups[2].Value;
                    if (prod.Name == "") prod.Name = "- no name -";
                    products.Add(prod);

                    prod.Photos.Add(new Photo(matches[i].Groups[1].Value));
                }

            }

            return products;
        }
    }
}
