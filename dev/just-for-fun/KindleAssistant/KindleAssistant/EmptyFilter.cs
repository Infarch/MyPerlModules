using System;
using System.Collections.Generic;
using System.Text;

namespace KindleAssistant
{
    class EmptyFilter : IContentFilter
    {
        public string Name
        {
            get { return "None"; }
        }

        public string Filter(string input)
        {
            return input;
        }
    }
}
