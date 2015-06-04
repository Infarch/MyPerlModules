using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.IO;

namespace Comagic2Megaplan
{
    /// <summary>
    /// A Logging class implementing the Singleton pattern and an internal Queue to be flushed perdiodically
    /// </summary>
    public class LogWriter
    {
        private static LogWriter instance;
        private static Queue<Log> logQueue;
        private static string logDir;
        private static int maxLogAge = 60;
        private static int queueSize = 50;
        private static DateTime LastFlushed = DateTime.Now;

        public static void Debug(string message)
        {
            Instance.WriteToLog("DEBUG", message);
        }

        public static void Debug(string message, int taskID)
        {
            Instance.WriteToLog("DEBUG", FormatMessageWithTaskID(message, taskID));
        }

        public static void Info(string message)
        {
            Instance.WriteToLog("INFO", message);
        }

        public static void Info(string message, int taskID)
        {
            Instance.WriteToLog("INFO", FormatMessageWithTaskID(message, taskID));
        }

        public static void Warn(string message)
        {
            Instance.WriteToLog("WARN", message);
        }

        public static void Warn(string message, int taskID)
        {
            Instance.WriteToLog("WARN", FormatMessageWithTaskID(message, taskID));
        }

        public static void Error(string message, Exception exc)
        {
            Instance.WriteToLog("ERROR", FormatMessageWithException(message, exc));
        }

        public static void Error(string message, int taskID, Exception exc)
        {
            Instance.WriteToLog("ERROR", FormatMessageWithException(FormatMessageWithTaskID(message, taskID), exc));
        }

        public static void Fatal(string message)
        {
            Instance.WriteToLog("FATAL", message);
        }

        public static void Fatal(string message, int taskID)
        {
            Instance.WriteToLog("FATAL", FormatMessageWithTaskID(message, taskID));
        }

        public static void Flush()
        {
            Instance.FlushLog();
        }

        private static string FormatMessageWithTaskID(string message, int taskID)
        {
            return string.Format("TaskID: {0}. {1}", taskID.ToString(), message);
        }

        private static string FormatMessageWithException(string message, Exception exc)
        {
            string ret = string.Format("{0}.\n\tException type: {1}\n\tMessage: {2}\n\tStack Trace: {3}",
                message, exc.GetType().ToString(), exc.Message, exc.StackTrace);
            Exception innerExc = exc.InnerException;
            if (innerExc != null)
            {
                ret += string.Format("\n\t\t{0}.\n\t\tException type: {1}\n\t\tMessage: {2}\n\t\tStack Trace: {3}",
                "Inner exception:", innerExc.GetType().ToString(), innerExc.Message, innerExc.StackTrace);
            }
            return ret;
        }

        /// <summary>
        /// Private constructor to prevent instance creation
        /// </summary>
        private LogWriter() { }

        /// <summary>
        /// An LogWriter instance that exposes a single instance
        /// </summary>
        private static LogWriter Instance
        {
            get
            {
                // If the instance is null then create one and init the Queue
                if (instance == null)
                {
                    instance = new LogWriter();
                    logQueue = new Queue<Log>();

                    // init logDir value
                    logDir = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "log");

                    // create log directory if it does not exist
                    if (!Directory.Exists(logDir))
                        Directory.CreateDirectory(logDir);
                }
                return instance;
            }
        }

        /// <summary>
        /// The single instance method that writes to the log file
        /// </summary>
        /// <param name="message">The message to write to the log</param>
        private void WriteToLog(string level, string message)
        {
            // Lock the queue while writing to prevent contention for the log file
            lock (logQueue)
            {
                // Create the entry and push to the Queue
                Log logEntry = new Log(level, message);
                logQueue.Enqueue(logEntry);
                Console.WriteLine(logEntry.ToString());

                // If we have reached the Queue Size then flush the Queue
                if (logQueue.Count >= queueSize || DoPeriodicFlush())
                {
                    FlushLog();
                }
            }
        }

        private bool DoPeriodicFlush()
        {
            TimeSpan logAge = DateTime.Now - LastFlushed;
            if (logAge.TotalSeconds >= maxLogAge)
            {
                LastFlushed = DateTime.Now;
                return true;
            }
            else
            {
                return false;
            }
        }

        /// <summary>
        /// Flushes the Queue to the physical log file
        /// </summary>
        private void FlushLog()
        {
            try
            {
                if (logQueue.Count > 0)
                {
                    string fileName = DateTime.Now.ToString("yyyy-MM-dd") + ".txt";
                    string logPath = Path.Combine(logDir, fileName);

                    using (FileStream fs = File.Open(logPath, FileMode.Append, FileAccess.Write))
                    using (StreamWriter log = new StreamWriter(fs))
                    {
                        while (logQueue.Count > 0)
                        {
                            log.WriteLine(logQueue.Dequeue().ToString());
                        }
                    }
                }
            }
            catch (Exception exc)
            {
                Console.WriteLine(FormatMessageWithException("Exception occured while flushing the log.", exc));
            }
        }
    }

    /// <summary>
    /// A Log class to store the message and the Date and Time the log entry was created
    /// </summary>
    internal class Log
    {
        string Level { get; set; }
        string Message { get; set; }
        public DateTime LogDate { get; private set; }

        public Log(string level, string message)
        {
            Level = level;
            Message = message;

            LogDate = DateTime.Now;
        }

        public override string ToString()
        {
            return string.Format("{0}\t{1}\t{2}", LogDate.ToString("yyyy-MM-dd HH:mm:ss"), Level, Message);
        }
    }

}
