using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Security.Cryptography;
using System.Windows.Forms;

namespace PicassaLib
{
     public class Photo
    {
        private String url;
        private String name;
        private String description;
        private CheckBox checkbox;
        private int groupnumber;
        private Boolean excluded;

        public Boolean Excluded
        {
            get { return excluded; }
            set { excluded = value; }
        }

        public int GroupNumber
        {
            get { return groupnumber; }
            set { groupnumber = value; }
        }

        public Boolean Checked
        {
            get
            {
                return this.CheckBox.Checked;
            }
            set { this.CheckBox.Checked = value; }
        }

        public String Hint
        {
            get
            {
                return this.CheckBox.Text;
            }
            set { this.CheckBox.Text = value; }
        }

        public CheckBox CheckBox
        {
            get
            {
                if (checkbox == null)
                {
                    checkbox = new CheckBox();
                }
                return checkbox; 
            }
            set { checkbox = value; }
        }

        public String Description
        {
            get { return description; }
            set { description = value; }
        }

        /// <summary>
        /// This is MD5 hash of the picture's URL
        /// </summary>
        public String Name
        {
            get { return name; }
            set { name = value; }
        }

        public String Url
        {
            get { return url; }
            set {

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
                    name = sb.ToString();
                }
                url = value;
            }
        }

        public Photo(String Url, String Description)
        {
            this.Url = Url;
            this.Description = Description;
        }
    }
}
