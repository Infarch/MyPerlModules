using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Text.RegularExpressions;
using System.Threading;

namespace ZapposLeech
{

    enum PhotoStatus { New, Downloaded, Processed, Rejected }
    enum PhotoSize { Large, Medium }

    class Photo
    {

        private static long counter = 0;

        string brand;
        string name;
        string price;
        string oldPrice;
        string sku;
        Uri uri;
        string fileName;
        PhotoStatus status;
        string subDirectory;
        PhotoSize photoSize;
        List<string> sizes = new List<string>();

        public List<string> Sizes
        {
            get { return sizes; }
        }
        public PhotoSize PhotoSize
        {
            get { return photoSize; }
            set { photoSize = value; }
        }
        public string SubDirectory
        {
            get { return subDirectory; }
            set { subDirectory = value; }
        }
        public PhotoStatus Status
        {
            get { return status; }
            set { status = value; }
        }

        public string OldPrice
        {
            get { return oldPrice; }
            set { oldPrice = value; }
        }
        public string FileName
        {
            get { return fileName; }
        }
        public Uri Uri
        {
            get { return uri; }
        }
        public string Sku
        {
            get { return sku; }
            set
            {
                sku = value;
                fileName = String.Format("{0}-{1:D6}.jpg", sku, Interlocked.Increment(ref counter));
            }
        }
        public string Price
        {
            get { return price; }
            set { price = value; }
        }
        public string Name
        {
            get { return name; }
            set { name = value; }
        }
        public string Brand
        {
            get { return brand; }
            set { brand = value; }
        }



        public Photo(string uri, PhotoSize psize)
        {
            this.uri = new Uri(uri);
            this.photoSize = psize;
            Status = PhotoStatus.New;
        }

    }
}
