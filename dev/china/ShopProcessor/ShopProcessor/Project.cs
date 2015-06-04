using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace ShopProcessor
{
    public class Project
    {
        private String title;
        private String directory;
        private DateTime created;
        private DateTime lastopen;
        private ProductList products = new ProductList();
        private String id;
        private List<String> fieldids = new List<String>();

        public List<String> FieldIDs
        {
            get { return fieldids; }
            set { fieldids = value; }
        }

        public String ID
        {
            get { return id; }
            set { id = value; }
        }

        public ProductList Products
        {
            get { return products; }
            set { products = value; }
        }

        public DateTime LastOpen
        {
            get { return lastopen; }
            set { lastopen = value; }
        }

        public DateTime Created
        {
            get { return created; }
            set { created = value; }
        }

        public String Directory
        {
            get { return directory; }
            set { directory = value; }
        }

        public String Title
        {
            get { return title; }
            set { title = value; }
        }



        public Project()
        {
            ID = Guid.NewGuid().ToString();
        }
    }
}
