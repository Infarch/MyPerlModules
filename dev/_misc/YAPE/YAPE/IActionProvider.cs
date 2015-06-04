using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace YAPE
{
    public interface IActionProvider
    {
        Action[] GetActions();
    }
}
