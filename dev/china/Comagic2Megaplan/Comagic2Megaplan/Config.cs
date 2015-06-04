using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Configuration;
using System.IO;
using System.Reflection;

namespace Comagic2Megaplan
{
    /// <summary>
    /// The main configuration collection for using in application anywhere
    /// </summary>
    class Config
    {
        private static string[] ignoreList;

        private const string DateTimeFile = "lasttime.txt";
        private static string DateTimeFilePath;

        private static DateTime lastTime;
        public static DateTime LastTime
        {
            get { return lastTime; }
            set
            {
                lastTime = value;
                // do not catch exceptions here! entire application should fail if so.
                File.WriteAllText(DateTimeFilePath, lastTime.ToString());
            }
        }

        private static int interval;
        public static int Interval
        {
            get
            {
                return interval;
            }
        }

        /// <summary>
        /// Checks whether a given number exists in the ignore list.
        /// </summary>
        /// <param name="number"></param>
        /// <returns></returns>
        public static bool NotForMegaplan(string number)
        {
            return ignoreList.Contains(number);
        }

        public static CmConfig Comagic { get; private set; }
        public static MegaConfig Megaplan { get; private set; }


        private static string CheckReadConfigOption(KeyValueConfigurationCollection collection, string key)
        {
            KeyValueConfigurationElement keyData = collection[key];
            if (keyData == null) throw new Exception("Key " + key + " does not exist in the given collection");
            string data = keyData.Value;
            if (string.IsNullOrWhiteSpace(data)) throw new ArgumentNullException(key, "The key value must be filled in in configuration file");
            return data;
        }

        static Config()
        {
            UserConfigSection ucs = ConfigurationManager.GetSection("UserConfig") as UserConfigSection;

            if (!int.TryParse(ucs.Misc["interval"].Value, out interval)) interval = 5;

            ignoreList = ucs.IgnoreList.AllKeys;
            
            Comagic = new CmConfig()
            {
                Login = CheckReadConfigOption(ucs.Comagic, "login"),
                Password = CheckReadConfigOption(ucs.Comagic, "password")
            };

            var mf = new MegaFields()
            {
                PhoneTo = CheckReadConfigOption(ucs.Megaplan, "fldPhoneTo"),
                WaitTime = CheckReadConfigOption(ucs.Megaplan, "fldWaitTime"),
                Duration = CheckReadConfigOption(ucs.Megaplan, "fldDuration"),
                AcId = CheckReadConfigOption(ucs.Megaplan, "fldAcId"),
                CallDate = CheckReadConfigOption(ucs.Megaplan, "fldCallDate"),
                Place = CheckReadConfigOption(ucs.Megaplan, "fldPlace")
            };

            Megaplan = new MegaConfig()
            {
                Login = CheckReadConfigOption(ucs.Megaplan, "login"),
                Password = CheckReadConfigOption(ucs.Megaplan, "password"),
                Host = CheckReadConfigOption(ucs.Megaplan, "host"),
                ResponsibleId = CheckReadConfigOption(ucs.Megaplan, "responsibleId"),
                Fields = mf
            };

            DateTimeFilePath = Path.Combine(Path.GetDirectoryName(System.Reflection.Assembly.GetEntryAssembly().Location), DateTimeFile);
            lastTime = new DateTime();
            if (File.Exists(DateTimeFilePath))
                try
                {
                    using (TextReader reader = new StreamReader(DateTimeFilePath))
                    {
                        string line = reader.ReadLine();
                        lastTime = DateTime.Parse(line);
                    }
                }
                catch { }

        }

        private Config() { }
    }

    /// <summary>
    /// Represents a set of Comagic configuration options. No sense to instantiate it elsewhere.
    /// </summary>
    class CmConfig
    {
        public string Login { get; set; }
        public string Password { get; set; }
    }

    /// <summary>
    /// Represents a set of Megaplan configuration options. No sense to instantiate it elsewhere.
    /// </summary>
    class MegaConfig
    {
        public string Login { get; set; }
        public string Password { get; set; }
        public string Host { get; set; }

        /// <summary>
        /// The person who is responsible for deals in Megaplan (take the number from an url like to:
        /// https://air-van.megaplan.ru/staff/1000000/card/)
        /// </summary>
        public string ResponsibleId { get; set; }

        public MegaFields Fields { get; set; }
    }

    /// <summary>
    /// Represents internal field names for sending data to Megaplan
    /// </summary>
    class MegaFields
    {
        public string PhoneTo { get; set; }
        public string WaitTime { get; set; }
        public string Duration { get; set; }
        public string AcId { get; set; }
        public string CallDate { get; set; }
        public string Place { get; set; }
    }

    /// <summary>
    /// Implementation of the ConfigurationSection class. Only for internal use! Do not create instances manually!
    /// </summary>
    class UserConfigSection : ConfigurationSection
    {

        [ConfigurationProperty("Comagic")]
        public KeyValueConfigurationCollection Comagic
        {
            get { return (KeyValueConfigurationCollection)(base["Comagic"]); }
        }

        [ConfigurationProperty("Megaplan")]
        public KeyValueConfigurationCollection Megaplan
        {
            get { return (KeyValueConfigurationCollection)(base["Megaplan"]); }
        }

        [ConfigurationProperty("IgnoreList")]
        public KeyValueConfigurationCollection IgnoreList
        {
            get { return (KeyValueConfigurationCollection)(base["IgnoreList"]); }
        }

        [ConfigurationProperty("Misc")]
        public KeyValueConfigurationCollection Misc
        {
            get { return (KeyValueConfigurationCollection)(base["Misc"]); }
        }

    }

}
