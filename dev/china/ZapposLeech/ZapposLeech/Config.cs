using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Drawing;

namespace ZapposLeech
{
    class Config
    {
        string folder;
        string prefix;
        FontFamily family;
        int percents;
        int brandSize;
        int nameSize;
        int bottomSize;
        Uri uri;
        int photosLimit;
        int directoryLimit;

        public int DirectoryLimit
        {
            get { return directoryLimit; }
        }
        public int PhotosLimit
        {
            get { return photosLimit; }
        }
        public Uri Uri
        {
            get { return uri; }
        }
        public int BottomSize
        {
            get { return bottomSize; }
        }
        public int NameSize
        {
            get { return nameSize; }
        }
        public int BrandSize
        {
            get { return brandSize; }
        }
        public int Percents
        {
            get { return percents; }
        }
        public FontFamily Family
        {
            get { return family; }
        }
        public string Prefix
        {
            get { return prefix; }
        }
        public string Folder
        {
            get { return folder; }
        }


        public Config(string folder, Uri uri, string prefix, FontFamily family, int percents, int brandSize, int nameSize, int bottomSize, int photosLimit, int directoryLimit)
        {
            this.folder = folder;
            this.uri = uri;
            this.prefix = prefix;
            this.family = family;
            this.percents = percents;
            this.brandSize = brandSize;
            this.nameSize = nameSize;
            this.bottomSize = bottomSize;
            this.photosLimit = photosLimit;
            this.directoryLimit = directoryLimit;
        }
    }
}
