using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace PriceProcessor.Controller
{
    class PriceInfo
    {
        float price;
        bool inStock;

        public bool InStock
        {
            get { return inStock; }
            set { inStock = value; }
        }
        public float Price
        {
            get { return price; }
            set { price = value; }
        }
    }
}
