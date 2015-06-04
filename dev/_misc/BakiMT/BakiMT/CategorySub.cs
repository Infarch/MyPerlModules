using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Net;
using System.Text.RegularExpressions;

namespace BakiMT
{
    public class CategorySub : CategoryMember
    {

        private int page = 1;

        public int Page
        {
            get { return page; }
            set { page = value; }
        }
        public override string GetTag()
        {
            return Page == 1 ? Name : Name + " (" + Page + ")";
        }

        public override string GetUrl()
        {
            return "http://baki.info/subcat/" + Id;
        }

        public String ProductsUrl(int page)
        {
            return "http://baki.info/ajax/get_srch_subcat.php?direct=subcat&id=" + Id + "&page=" + page;
        }

        public override MemberList Process(WebClient client)
        {
            MemberList ml = new MemberList();
            String content = client.DownloadString(GetUrl());

            MatchCollection mc = Regex.Matches(content,
                "<a href=\"http://baki\\.info/subcat/(\\d+)\" class=\"sc_listone\">.*?<span class=\"csc_sub_name\"><div class=\"title_inner\">(.+?)</div>", RegexOptions.Singleline);
            if (mc.Count > 0)
            {
                // process sub categories
                foreach (Match m in mc)
                {
                    CategorySub c = new CategorySub();
                    c.Id = m.Groups[1].Value;
                    c.Name = m.Groups[2].Value.Replace("&nbsp;", " ").Replace("&amp;", "&").Trim();

                    Children.Add(c);
                    ml.Add(c);
                }

                Unprocessed = false;
            }
            else
            {
                // process products
                content = client.DownloadString(ProductsUrl(page));

                MatchCollection mc1 = Regex.Matches(content, "<div class=\"cop_title\"><h3><a href=\"(.+?)\">(.+?)</a></h3></div>");

                foreach (Match m in mc1)
                {
                    Product p = new Product();
                    p.Name = m.Groups[2].Value.Replace("&nbsp;", " ").Replace("&amp;", "&").Trim();
                    p.Url = m.Groups[1].Value;
                    
                    Children.Add(p);
                    ml.Add(p);
                }


                MatchCollection mc2 = Regex.Matches(content, "new Paginator\\('paginator1', (\\d+?), \\d+, (\\d+?), \"#\"\\);");
                String total = mc2[0].Groups[1].Value;
                String current = mc2[0].Groups[2].Value;

                if (page < Int16.Parse(total))
                {
                    Page++;
                    ml.Add(this);
                }
                else
                {
                    Unprocessed = false;
                }

            }
            
            return ml;
        }
    }
}
