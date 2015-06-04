using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Windows.Forms;

namespace ShopProcessor.Shops
{
    public enum ShopPageType { List, Card };

    abstract public class Shop
    {
        //private ShopPageType pagetype;
        private String title;

        public static String default_name = "-- new product --";

        abstract public String GetDomain();
        abstract public List<Product> ExtractProducts(HtmlDocument document);

        public bool MatchDomain(String url)
        {
            return ExtractDomain(url) == GetDomain();
        }

        public String ExtractDomain(String Url)
        {
            if (!Url.Contains("://"))
                Url = "http://" + Url;
            return new Uri(Url).Host;
        }

        public String Title
        {
            get { return title; }
            set { title = value; }
        }
        /*
        public ShopPageType PageType
        {
            get { return pagetype; }
            set { pagetype = value; }
        }
        */
    }
}
