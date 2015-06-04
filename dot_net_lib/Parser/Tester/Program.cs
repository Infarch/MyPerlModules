using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

using ParseLib.Database;
using ParseLib.Classes;

namespace Tester
{
    class MyParser : AbstactParser
    {
        public MyParser(string server, string db):base(server, db){}
    }

    class Program
    {
        static void Main(string[] args)
        {
            MyParser parser = new MyParser("EXECUTOR\\SQLEXPRESS", "TestParseBaseNew");

        }
    }
}
