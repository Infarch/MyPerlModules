using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace PicassaLib
{
    public class Product
    {
        public static int pLimit = 15;

        private String description;

        public String Description
        {
            get { return description; }
            set { description = value; }
        }

        private List<Photo> Photos = new List<Photo>();

        public Product(Photo p)
        {
            addPhoto(p);
        }

        public void addPhoto(Photo p){
            if (Photos.Count < pLimit)
            {
                Photos.Add(p);
                if (Description == null)
                {
                    Description = p.Description;
                }
            }
        }

        public String[] getPhotoNames()
        {
            int pc = Photos.Count;
            String[]pn = new String[pc];
            for (int i = 0; i < pc; i++)
            {
                pn[i] = Photos[i].Name;
            }
            return pn;
        }
    }
}
