using System;
using System.Text;
using System.Net;

namespace BakiMT
{
    public abstract class CategoryMember : AbstractMember
    {

        //private int page = 1;
        //private bool isTopCategory = false;
        private String id;
        //private bool isRootCategory = false;

        //public bool IsRootCategory
        //{
        //    get { return isRootCategory; }
        //    set { isRootCategory = value; }
        //}
        public String Id
        {
            get { return id; }
            set { id = value; }
        }
        //public bool IsTopCategory
        //{
        //    get { return isTopCategory; }
        //    set { isTopCategory = value; }
        //}
        //public int Page
        //{
        //    get { return page; }
        //    set { page = value; }
        //}

        //private String Url()
        //{
        //    return IsRootCategory ? "http://baki.info" : IsTopCategory ? "http://baki.info/cat/" + id : "http://baki.info/subcat/" + id;
        //}

        //public override string GetTag()
        //{
        //    return Url() + " (" + page + ")";
        //}

        //public override MemberList Process(WebClient client)
        //{
        //    throw new NotImplementedException();
        //}
    }
}
