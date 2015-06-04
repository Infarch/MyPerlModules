using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

using System.Diagnostics;

namespace ChampsSportsHelper
{
    partial class Form1
    {
        protected void Echo(string format, params object[]args)
        {
            Debug.WriteLine(format, args);
        }
    }
}
