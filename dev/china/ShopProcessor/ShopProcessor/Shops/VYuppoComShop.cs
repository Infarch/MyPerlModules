using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Windows.Forms;
using System.Text.RegularExpressions;

namespace ShopProcessor.Shops
{
    class VYuppoComShop : Shop
    {
        public override string GetDomain()
        {
            return "v.yupoo.com";
        }

        public override List<Product> ExtractProducts(System.Windows.Forms.HtmlDocument document)
        {
            List<Product> products = new List<Product>();
            Product prod = new Product();

            prod.Name = default_name;

            foreach (HtmlElement meta in document.GetElementsByTagName("meta"))
            {
                if (meta.GetAttribute("name") == "title") prod.Name = meta.GetAttribute("content");
            }

            products.Add(prod);

            foreach (HtmlElement img in document.Images)
            {
                String src = Regex.Replace(img.GetAttribute("src"), "small|square", "big");
                prod.Photos.Add(new Photo(src));
            }

            return products;
        }
    }
}
