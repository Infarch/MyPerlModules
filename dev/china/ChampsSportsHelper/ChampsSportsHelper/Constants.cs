using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.IO;
namespace ChampsSportsHelper
{
    class Constants
    {
        public static string Location = Path.GetDirectoryName(System.Reflection.Assembly.GetExecutingAssembly().Location);
        public static string DownloadsDir = Path.Combine(Location, "downloads");
        public static string ExportsDir = Path.Combine(Location, "exports");
        public static string StopListFile = Path.Combine(Location, "stoplist.txt");
    }
}
