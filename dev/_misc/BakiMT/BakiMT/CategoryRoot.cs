using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Net;
using System.Text.RegularExpressions;

namespace BakiMT
{
    public class CategoryRoot : CategoryMember
    {
        public override string GetTag()
        {
            return Name;
        }

        public override string GetUrl()
        {
            return "http://baki.info";
        }

        public override MemberList Process(WebClient client)
        {
            MemberList ml = new MemberList();

            String content = client.DownloadString(GetUrl());

            MatchCollection mc = Regex.Matches(content, "<option value=\"(\\d+)\">(.+?)</option>");
            foreach (Match m in mc)
            {
                String id = m.Groups[1].Value;
                String name = m.Groups[2].Value;

                if (id != "0")
                {
                    CategoryTop c = new CategoryTop();
                    c.Name = name;
                    c.Id = id;

                    Children.Add(c);
                    ml.Add(c);
                }
            }

            Unprocessed = false;
            return ml;
        }
    }
}
