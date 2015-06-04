using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace Comagic2Megaplan
{
    partial class Program
    {
        // used for processing command line arguments
        static Action<string> commandProcessor = CommandReader;

        static void CommandsHelp()
        {
            Console.WriteLine(@"Command line options:
-h  : Show the help
-tl megaplan|comagic : Perform a test login into either Megaplan or Comagic
-st : Set the start time for searching calls. Must be Moskow time!!!");
        }

        static void CommandReader(string cmd)
        {
            switch (cmd)
            {
                case "-h":
                    CommandsHelp();
                    break;
                case "-tl":
                    commandProcessor = HandleTest;
                    break;
                case "-st":
                    commandProcessor = HandleTime;
                    break;
                default:
                    Console.WriteLine("Invalid argument {0}. Use -h to see more...", cmd);
                    break;
            }
        }

        private static void HandleTime(string val)
        {
            DateTime oldTime = Config.LastTime;
            Console.WriteLine("The old time value was {0} (Moskow)", oldTime);

            DateTime newTime = DateTime.Parse(val);

            Console.WriteLine("The new time value is {0} (Moskow)", newTime);

            Config.LastTime = newTime;

            commandProcessor = CommandReader;
        }

        private static void HandleTest(string system)
        {
            switch (system)
            {
                case "comagic":
                    TestComagickLogin();
                    break;
                case "megaplan":
                    TestMegaplanLogin();
                    break;
                default:
                    throw new ArgumentException("Must be either comagic or megaplan", "-tl");
            }

            commandProcessor = CommandReader;
        }


    }
}
