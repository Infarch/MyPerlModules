using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Windows.Forms;
using System.Text.RegularExpressions;

namespace BAKi
{
    public class Leaf : Member
    {

        #region properties

        private String address = "";
        private List<String> phones = new List<string>();
        //private List<String> faxes = new List<string>();
        private String email = "";
        private String coords = "";
        private List<String> sites = new List<string>();

        public List<String> Sites
        {
            get { return sites; }
            set { sites = value; }
        }

        public String Coords
        {
            get { return coords; }
            set { coords = value; }
        }

        public String Email
        {
            get { return email; }
            set { email = value; }
        }

        //public List<String> Faxes
        //{
        //    get { return faxes; }
        //    set { faxes = value; }
        //}

        public List<String> Phones
        {
            get { return phones; }
            set { phones = value; }
        }

        public String Address
        {
            get { return address; }
            set { address = value; }
        }

        #endregion

        public Leaf(String name, String url)
        {
            Name = name;
            Url = url;
        }

        public Leaf()
        {
            // does nothing, just for serializer
        }

        public override void Process(HtmlDocument doc)
        {
            Processed = true;

            HtmlElement details = null;
            bool hasAddress = false;
            bool hasDetails = false;
            foreach (HtmlElement div in doc.GetElementsByTagName("div"))
            {
                String cn = div.GetAttribute("className");
                if (cn == "cop_address")
                {
                    Address = div.InnerText;
                    hasAddress = true;
                }
                else if (cn == "cop_contact_inf")
                {
                    details = div;
                    hasDetails = true;
                }
                if (hasAddress && hasDetails)
                    break;
            }

            // process details
            foreach (HtmlElement li in details.GetElementsByTagName("li"))
            {
                String cname = li.FirstChild.GetAttribute("className");
                if (cname == "call_i")
                {
                    Phones.Add(li.Children[1].InnerText.Trim());
                }
                else if (cname == "web_i")
                {
                    Sites.Add(li.Children[1].InnerText.Trim());
                }
                else
                {
                    MessageBox.Show(Url.ToString() + ": " + cname);
                }
            }

            // coordinates
            MatchCollection matches = Regex.Matches(doc.Body.InnerHtml, "google\\.maps\\.LatLng\\((.*?)\\)");
            if (matches.Count > 0)
            {
                Coords = matches[0].Groups[1].Value;
            }
        }
    }
}
