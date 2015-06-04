using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using YAPE;
namespace Tester
{
    class ArgProvider:IArgumentProvider
    {
        int limit = 500;
        int blocks = 100;

        int x = 0;

        public object[] GetArguments()
        {
            List<Object> args = new List<Object>();
            
            if (blocks-- > 0)
            {

                //if (blocks == 50) throw new Exception();

                for (int i = 0; i < 10; i++)
                {
                    args.Add("Object " + x++);
                }
            }

            return args.ToArray();
        }
    }
}
