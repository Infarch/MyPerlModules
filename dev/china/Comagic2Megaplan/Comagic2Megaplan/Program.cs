using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Threading;
using System.IO;

namespace Comagic2Megaplan
{
    partial class Program
    {

        static string TmpDirName;
        
        static void Start()
        {
            try
            {
                LogWriter.Info("Application started");
                Program p = new Program();

                int interval = Config.Interval;

                TmpDirName = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "tmp");
                try
                {
                    if (!Directory.Exists(TmpDirName)) Directory.CreateDirectory(TmpDirName);
                }
                catch (Exception e)
                {
                    LogWriter.Error("Error creating a temporary directory", e);
                    return;
                }

                p.Worker(interval);

                LogWriter.Info("Application finished");
            }
            catch (Exception e)
            {
                try
                {
                    LogWriter.Error("Application error", e);
                }
                catch (Exception e1)
                {
                    Console.WriteLine("Cannot create a log record regarding an application fail: {0}", e1.Message);
                }

            }
            finally
            {
                LogWriter.Flush();
            }
        }


        static void Main(string[] args)
        {
            // no arguments - just start the app
            if (args.Length == 0)
            {
                Start();
                return;
            }

            foreach (string arg in args) commandProcessor(arg.ToLower());

        }

        private static DateTime Utc2Moskow(DateTime utcTime)
        {
            // there is something unusual regarding the Moskow time zone.
            // Instead of using a TimeZoneInfo instance I just add 3 hours to the utc time
            return utcTime + TimeSpan.FromHours(3);

            /*
            TimeZoneInfo tzi = TimeZoneInfo.FindSystemTimeZoneById("Russian standard time");
            DateTime mdt = TimeZoneInfo.ConvertTimeFromUtc(utcTime, tzi);
            */
        }

    }
}
