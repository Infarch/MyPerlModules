using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Text.RegularExpressions;

namespace ShopProcessor.CSV
{
    public class Field
    {
        public const string Article = "code";
        public const string Name = "name";

        public static string PhotoName(int number)
        {
            return "photo_" + number;
        }

        private String title;
        private Boolean quote = false;
        private String deflt;
        private String id;
        private bool visiblebydefault = false;
        private bool hidden = false;
        private bool custom = false;

        public bool Custom
        {
            get { return custom; }
            set { custom = value; }
        }

        public bool Hidden
        {
            get { return hidden; }
            set { hidden = value; }
        }

        public bool VisibleByDefault
        {
            get { return visiblebydefault; }
            set { visiblebydefault = value; }
        }

        public String ID
        {
            get { return id; }
            set { id = value; }
        }

        public String Default
        {
            get { return deflt; }
            set { deflt = value; }
        }
        public Boolean Quote
        {
            get { return quote; }
            set { quote = value; }
        }
        public String Title
        {
            get { return title; }
            set { title = value; }
        }

        public Field()
        {
            // this is only for serialization
        }

        public Field(String title, String id, Boolean quote, String deflt, bool defaultvisible, bool hidden) 
            : this(title, id, quote, deflt)
        {
            VisibleByDefault = defaultvisible;
            Hidden = hidden;
        }

        public Field(String title, String id, Boolean quote, String deflt)
        {
            Title = title;
            ID = id;
            Quote = quote;
            Default = deflt;
        }

        public Field(String title, String id, Boolean custom):this(title, id, false, null)
        {
            this.custom = custom;
        }

        public void RenderTo(StringBuilder sb, String value, String separator, Boolean quote)
        {
            if (value != null)
            {
                if (Regex.IsMatch(value, separator, RegexOptions.IgnoreCase) || quote)
                {
                    sb.Append("\"" + value + "\"");
                }
                else
                {
                    sb.Append(value);
                }
            }
        }

        public void RenderTo(StringBuilder sb, String value, String separator)
        {
            RenderTo(sb, value, separator, false);
        }

        public void AppendValueTo(StringBuilder sb, Dictionary<String, String> dic)
        {
            String val = null;
            dic.TryGetValue(ID, out val);
            if (val == null)
            {
                // try default
                if (!dic.ContainsKey("suppress_defaults"))
                {
                    val = Default;
                }
            }
            // do we have any value?
            if (val != null)
            {
                RenderTo(sb, val, ";", Quote);
            }

        }

        override public String ToString() { return Title; }

    }
}
