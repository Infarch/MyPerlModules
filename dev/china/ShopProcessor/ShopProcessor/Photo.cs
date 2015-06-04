using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Security.Cryptography;
using System.ComponentModel;

namespace ShopProcessor
{
    public class Photo : INotifyPropertyChanged
    {
        private String url;
        private String md5;
        private Boolean isdownloaded;
        
        private String projectdir;
        private String projectid;
        private Boolean isactive;

        public Boolean IsActive
        {
            get { return isactive; }
            set 
            { 
                isactive = value;
                //NotifyPropertyChanged("IsActive");
            }
        }

        public String ProjectID
        {
            get { return projectid; }
            set { projectid = value; }
        }

        public String ProjectDir
        {
            get { return projectdir; }
            set { projectdir = value; }
        }

        public Boolean IsDownloaded
        {
            get { return isdownloaded; }
            set
            {
                isdownloaded = value;
                NotifyPropertyChanged("IsDownloaded");
            }
        }

        public String MD5Hash
        {     
            get { return md5; }
            set { md5 = value; }
        }

        public String Url
        {
            get { return url; }
            set
            {
                if (value != url)
                {
                    MD5 md5 = MD5.Create();
                    byte[] bytes = System.Text.Encoding.ASCII.GetBytes(value);
                    byte[] hash = md5.ComputeHash(bytes);
                    StringBuilder sb = new StringBuilder();
                    for (int i = 0; i < hash.Length; i++)
                    {
                        sb.Append(hash[i].ToString("X2"));
                    }
                    MD5Hash = sb.ToString();
                }
                url = value;
            }
        }




        public Photo() { }

        public Photo(String Url)
        {
            this.Url = Url;
        }

        private void NotifyPropertyChanged(String info)
        {
            if (PropertyChanged != null)
            {
                PropertyChanged(this, new PropertyChangedEventArgs(info));
            }
        }

        public event PropertyChangedEventHandler PropertyChanged;
    }
}
