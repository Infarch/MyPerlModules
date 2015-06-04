using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace PriceProcessor.Controller
{
    class SearchItem
    {
        long id;
        long productId;
        long engineId;
        string name;
        string url;
        string price;

        public string Price
        {
            get { return price; }
            set { price = value; }
        }
        public string Url
        {
            get { return url; }
            set { url = value; }
        }
        public string Name
        {
            get { return name; }
            set { name = value; }
        }
        public long EngineId
        {
            get { return engineId; }
            set { engineId = value; }
        }
        public long ProductId
        {
            get { return productId; }
            set { productId = value; }
        }
        public long Id
        {
            get { return id; }
            set { id = value; }
        }
    }
}
