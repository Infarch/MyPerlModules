using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace PriceProcessor.Controller
{
    abstract class SearchEngine
    {

        long id;

        public Encoding Encoding
        {
            get { return GetEncoding(); }
        }
        public string Name
        {
            get { return GetName(); }
        }
        public long Id
        {
            get { return id; }
            set { id = value; }
        }

        protected abstract string GetName();
        protected abstract Encoding GetEncoding();
        protected abstract string GetAbsoluteUri(string part);

        public abstract string GetSearchUrl(string product_name);
        public abstract SearchItem[] ExtractSearchItems(string content);
        public abstract PriceInfo ExtractPriceInfo(string content);

    }
}
