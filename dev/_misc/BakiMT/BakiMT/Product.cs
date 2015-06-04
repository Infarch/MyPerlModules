using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Net;
using System.Text.RegularExpressions;

namespace BakiMT
{
    public class Product : AbstractMember
    {
        private String url;
        private String address;
        private List<String> phones = new List<string>();
        private List<String> emails = new List<string>();
        private List<String> sites = new List<string>();
        private String coords = "";

        public String Coords
        {
            get { return coords; }
            set { coords = value; }
        }
        public List<String> Sites
        {
            get { return sites; }
            set { sites = value; }
        }
        public List<String> Emails
        {
            get { return emails; }
            set { emails = value; }
        }
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
        public String Url
        {
            get { return url; }
            set { url = value; }
        }

        public override string GetTag()
        {
            return Name;
        }

        public override string GetUrl()
        {
            return Url;
        }

        public override MemberList Process(WebClient client)
        {
            String content = client.DownloadString(GetUrl());

            ExtractAddress(content);
            ExtractPhones(content);
            ExtractEmails(content);
            ExtractSites(content);
            ExtractCoords(content);

            Unprocessed = false;
            return null;
        }

        private void ExtractCoords(string content)
        {
            MatchCollection matches = Regex.Matches(content, "google\\.maps\\.LatLng\\((.*?)\\)");
            if (matches.Count > 0)
            {
                Coords = matches[0].Groups[1].Value;
            }
        }

        private void ExtractSites(string content)
        {
            MatchCollection mc = Regex.Matches(content, "<li><span class=\"web_i\"></span><a href=\"(.+?)\" target=\"_blank\">");
            foreach (Match m in mc)
            {
                Sites.Add(m.Groups[1].Value.Trim());
            }
        }

        private void ExtractEmails(string content)
        {
            MatchCollection mc = Regex.Matches(content, "<li><span class=\"mail_i\"></span><a href=\"mailto:.+?\">(.+?)</a></li>");
            foreach (Match m in mc)
            {
                Emails.Add(m.Groups[1].Value.Trim());
            }
        }

        private void ExtractPhones(string content)
        {
            MatchCollection mc = Regex.Matches(content, "<li><span class=\"call_i\"></span><p>(.+?)</p></li>");
            foreach(Match m in mc)
            {
                Phones.Add(m.Groups[1].Value.Trim());
            }
        }

        private void ExtractAddress(string content)
        {
            MatchCollection mc = Regex.Matches(content, "<div class=\"cop_address\">(.+?)</div>");
            Address = mc[0].Groups[1].Value.Replace("&nbsp;", " ").Replace("&amp;", "&").Trim();
        }
    }
}
