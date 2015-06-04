using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.ComponentModel;
using System.Drawing;

namespace ShopProcessor.UI
{
    public class PhotoBinder : INotifyPropertyChanged
    {

        private Image _blank = new Bitmap(1, 1);
        private String root;

        private Photo photo;
        private Image img;
        private String infotext = "";

        public String InfoText
        {
            get { return infotext; }
            set 
            { 
                infotext = value;
                NotifyPropertyChanged("InfoText");
            }
        }

        public Image Img
        {
            get { return img; }
            set 
            { 
                img = value;
                NotifyPropertyChanged("Img");
            }
        }

        private PhotoBinder() { }

        public PhotoBinder(String root)
        {
            img = _blank;
            this.root = root;
        }

        public void SetProduct(Product prod)
        {
            if (prod.Photos.Count == 0)
            {
                InfoText = "This product has no photo";
                SetPhoto(null);
            }
            else if (prod.Photos.Count == 1)
            {
                InfoText = "";
                SetPhoto(prod.Photos[0]);
            }
            else
            {
                InfoText = "Warning:\nthere are several photos\nin the product.";
                SetPhoto(prod.Photos[0]);
            }
        }

        public void SetPhoto(Photo p)
        {
            if (photo != null) photo.PropertyChanged -= new PropertyChangedEventHandler(photo_PropertyChanged);
            photo = p;
            if (photo != null) photo.PropertyChanged += new PropertyChangedEventHandler(photo_PropertyChanged);
            ShowImage();
        }

        private void ShowImage()
        {
            if (photo == null)
            {
                Img = _blank;
            }
            else
            {
                if (photo.IsDownloaded)
                {
                    Img = Image.FromFile(FileHelper.PathToPhoto(root, photo));
                }
                else
                {
                    Img = ShopProcessor.Properties.Resources.PendingImage;
                }
            }
        }

        void photo_PropertyChanged(object sender, PropertyChangedEventArgs e)
        {
            if (e.PropertyName == "IsDownloaded") ShowImage();
        }





        public event PropertyChangedEventHandler PropertyChanged;

        private void NotifyPropertyChanged(String info)
        {
            if (PropertyChanged != null)
            {
                PropertyChanged(this, new PropertyChangedEventArgs(info));
            }
        }

    }
}
