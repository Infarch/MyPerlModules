using System;
using System.Text.RegularExpressions;
using System.Text;

namespace KindleAssistant
{
    class LibRuFilter : IContentFilter
    {
        public string Name
        {
            get { return "Lib.RU"; }
        }

        public string Filter(string input)
        {
            String file = Regex.Replace(input, "^     ", "<p>", RegexOptions.Multiline);
            file = Regex.Replace(file, "\n", " ");
            file = Regex.Replace(file, "\\s{2,}", " ");
            file = Regex.Replace(file, "<p>", "\n<p>");
            file = Regex.Replace(file, "([^-])--([^-])", "$1-$2");
            file = Regex.Replace(file, "<pre>", "");

            return file;
        }
    }
}
