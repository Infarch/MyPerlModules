using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Net;

namespace BakiMT
{
    public abstract class AbstractMember
    {

        private bool unprocessed = true;
        private String name;
        private MemberList children = new MemberList();

        public MemberList Children
        {
            get { return children; }
            set { children = value; }
        }
        public String Name
        {
            get { return name; }
            set { name = value; }
        }
        public bool Unprocessed
        {
            get { return unprocessed; }
            set { unprocessed = value; }
        }


        public abstract String GetTag();
        public abstract String GetUrl();
        public abstract MemberList Process(WebClient client);

        public MemberList GetUnprocessedChildren()
        {
            MemberList ml = new MemberList();
            Children.ForEach(delegate(AbstractMember m)
            {
                ml.AddRange(m.GetUnprocessedChildren());
            });
            return ml;
        }

    }
}
