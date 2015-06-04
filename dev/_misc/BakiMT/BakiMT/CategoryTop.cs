using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Net;
using System.Text.RegularExpressions;

namespace BakiMT
{
    public class CategoryTop : CategoryMember
    {
        public override string GetTag()
        {
            return Name;
        }

        public override string GetUrl()
        {
            return "http://baki.info/cat/" + Id;
        }

        public override MemberList Process(WebClient client)
        {
            MemberList ml = new MemberList();
            String content = client.DownloadString(GetUrl());

            MatchCollection mc = Regex.Matches(content,
                "<a href=\"http://baki\\.info/subcat/(\\d+)\" class=\"sc_listone\">.*?<span class=\"csc_sub_name\"><div class=\"title_inner\">(.+?)</div>", RegexOptions.Singleline);
            foreach (Match m in mc)
            {
                CategorySub c = new CategorySub();
                c.Id = m.Groups[1].Value;
                c.Name = m.Groups[2].Value;

                Children.Add(c);
                ml.Add(c);

            }

            Unprocessed = false;
            return ml;
        }
    }
}
