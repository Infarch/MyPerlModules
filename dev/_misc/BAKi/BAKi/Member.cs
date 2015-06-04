using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Windows.Forms;
using System.Xml.Serialization;

namespace BAKi
{
    [XmlInclude(typeof(Leaf))]
    public abstract class Member
    {
        public enum Type { TopCategory, SubCategory, Leaf };
        private bool processed = false;
        private String name;
        private Type memberType;

        private String url;

        public String Url
        {
            get { return url; }
            set { url = value; }
        }

        private List<Member> children = new List<Member>();

        public List<Member> Children
        {
            get { return children; }
            set { children = value; }
        }
        public Type MemberType
        {
            get { return memberType; }
            set { memberType = value; }
        }
        public String Name
        {
            get { return name; }
            set { name = value; }
        }
        public bool Processed
        {
            get { return processed; }
            set { processed = value; }
        }


        public abstract void Process(HtmlDocument doc);

        public Member getNextUnprocessed()
        {
            Member x = null;
            if (!Processed)
            {
                x = this;
            }
            else
            {
                foreach (Member m in children)
                {
                    x = m.getNextUnprocessed();
                    if (x != null) break;
                }
            }

            return x;
        }
    }
}
