using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Text.RegularExpressions;
using System.Web;

namespace PriceProcessor.Controller.Engines
{
    class MtOnline : SearchEngine
    {
        Uri baseUri = new Uri("http://www.mtonline.ru/");

        protected override string GetName()
        {
            return "mtonline.ru";
        }

        protected override Encoding GetEncoding()
        {
            return Encoding.UTF8;
        }

        protected override string GetAbsoluteUri(string part)
        {
            return (new Uri(baseUri, part)).ToString();
        }

        public override SearchItem[] ExtractSearchItems(string content)
        {
            List<SearchItem> items = new List<SearchItem>();
            string pattern = "<p class=\"second_name\"><a href=\"(.+?)\" title=\"(.+?)\">[^<]+</a></p>(<p class=\"cost2\">([^<]+)<|)";
            MatchCollection matches = Regex.Matches(content, pattern);
            foreach (Match m in matches)
            {
                SearchItem item = new SearchItem()
                {
                    EngineId = this.Id,
                    Name = m.Groups[2].Value,
                    Price = m.Groups[4].Value,
                    Url = GetAbsoluteUri(m.Groups[1].Value)
                };
                items.Add(item);
            }
            return items.ToArray();

        }

        public override PriceInfo ExtractPriceInfo(string content)
        {
            bool instock = false;
            float price = 0f;

            if (!Regex.IsMatch(content, "<div id=\"ctl00_ctl00_cphGeneral_cphMain_lblUnavailable\" class=\"cost5\">Товара сейчас нет в наличии</div>"))
            {
                // product exists, get price
                Match m = Regex.Match(content, "<div id=\"ctl00_ctl00_cphGeneral_cphMain_lblCost\" class=\"cost\">(.+?)<span class='rub'>");
                if (!m.Success) throw new Exception("Bad content");
                string sprice = m.Groups[1].Value.Replace(" ", String.Empty);
                price = float.Parse(sprice);
                instock = true;
            }
            
            PriceInfo pi = new PriceInfo()
            {
                Price = price,
                InStock = instock
            };
            return pi;
        }

        public override string GetSearchUrl(string product_name)
        {
            return "http://www.mtonline.ru/SearchResults/?text=" + HttpUtility.UrlEncode(product_name);
        }
    }
}
