using System;
using System.Collections.Generic;
using System.Text;

namespace KindleAssistant
{
    public interface IContentFilter
    {
        String Name { get; }

        String Filter(String input);

    }
}
