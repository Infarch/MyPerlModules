using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Windows.Forms;
using System.ComponentModel;
using System.Drawing;

namespace ShopProcessor.UI
{
    public class PhotoListViewItem : ListViewItem
    {
        private Photo photo;
        private ImageList img_list;
        private String img_path;

        public void PhotoIsActive(Boolean state)
        {
            photo.IsActive = state;
        }

        public PhotoListViewItem(ImageList l, Photo p, String ip)
        {
            img_list = l;
            photo = p;
            img_path=ip;

            base.Checked = photo.IsActive;
            if (photo.IsDownloaded)
            {
                base.Text = "Ready";
                SetImage();
            }
            else
            {
                base.Text = "Pending";
                base.ImageIndex = 0;
            }

            photo.PropertyChanged += new PropertyChangedEventHandler(photo_PropertyChanged);
        }

        private void SetImage()
        {
            Image img = Image.FromFile(img_path);
            img_list.Images.Add(img);
            base.ImageIndex = img_list.Images.Count - 1;
        }

        void photo_PropertyChanged(object sender, PropertyChangedEventArgs e)
        {
            switch (e.PropertyName)
            {
                case "IsDownloaded":
                    base.Text = "Ready";
                    SetImage();
                    break;
                default:
                    break;
            }
        }
    }
}
