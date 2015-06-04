using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.ComponentModel;

namespace ShopProcessor
{
    public class Product : INotifyPropertyChanged
    {

        private string name;
        private PhotoList photos;
        private ProductData data = new ProductData();

        public ProductData Data
        {
            get { return data; }
            set { data = value; }
        }

        public PhotoList Photos
        {
            get { return photos; }
            set { photos = value; }
        }

        public string Name
        {
            get { return name; }
            set { name = value; NotifyPropertyChanged("Name"); }
        }

        public void SetData(String key, String value)
        {
            if (Data.ContainsKey(key))
            {
                Data.Remove(key);
            }
            Data.Add(key, value);
        }

        public String GetData(String key)
        {
            if (Data.ContainsKey(key))
                return Data[key];
            else
                return null;
        }

        public Product()
        {
            photos = new PhotoList();
        }

        public event PropertyChangedEventHandler PropertyChanged;

        private void NotifyPropertyChanged(String info)
        {
            if (PropertyChanged != null)
            {
                PropertyChanged(this, new PropertyChangedEventArgs(info));
            }
        }

        override public String ToString() { return Name; }
    }
}
