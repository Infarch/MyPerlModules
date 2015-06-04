using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading;

using YAPE;

namespace Tester
{
    class ActionProvider : IActionProvider
    {
        int total = 10000;
        int current = 0;

        public Action[] GetActions()
        {
            List<Action> actions = new List<Action>();
            for (int i = 0; i < 100; i++)
            {
                if (current++ == total) break;
                int x = current;
                Action a = new Action(() =>
                {
                    Console.WriteLine("Started {0}", x);
                    if (x == 33) throw new Exception();
                    Thread.Sleep(100);
                });
                actions.Add(a);
            }
            return actions.ToArray();
        }
    }
}
