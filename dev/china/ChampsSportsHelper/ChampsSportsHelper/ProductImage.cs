using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace ChampsSportsHelper
{
    class ProductImage
    {
        /// <summary>
        /// Local name of the image WITHOUT EXTENSION!
        /// </summary>
        public string Name { get; private set; }
        public string Url { get; private set; }
        public Boolean Downloaded { get; set; }

        public ProductImage(string name, string url)
        {
            Name = name;
            Url = url;
            Downloaded = false;
        }
    }
}
