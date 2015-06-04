using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace Comagic2Megaplan
{
    partial class Program
    {

        private static void TestMegaplanLogin()
        {
            Console.WriteLine("Testing Megaplan login...");
            Megaplan.Api x = new Megaplan.Api(Config.Megaplan.Host, Config.Megaplan.Login, Config.Megaplan.Password);
            Console.WriteLine("Done.");
            Console.WriteLine("Trying to search clients...");
            var yy = x.FindClients("80983344567", 3);
            Console.WriteLine("Done");
        }

        private static void TestComagickLogin()
        {
            //Console.WriteLine("Testing Comagic login... '{0}'-'{1}'", Config.Comagic.Login, Config.Comagic.Password);
            Console.WriteLine("Testing Comagic login...");
            Comagic.Api x = new Comagic.Api(Config.Comagic.Login, Config.Comagic.Password);
            Console.WriteLine("Done.");

            // read calls 27.01.2015 14:58:50
            Console.WriteLine("trying to search calls...");
            DateTime from = new DateTime(2015, 1, 27, 15, 2, 0);
            DateTime to = from + TimeSpan.FromMinutes(1);
            var calls = x.GetCalls(from, to);
            Console.WriteLine("Done. Found {0} call(s)", calls.Count);

            Console.WriteLine("Performing logout...");
            x.Logout();
            Console.WriteLine("Done");
        }

    }
}
