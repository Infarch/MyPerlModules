using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Threading;
using System.Net;
using System.IO;

namespace ChampsSportsHelper
{
    /// <summary>
    /// Common entry point for all web operations. We need this class in order to limit concurrent http requests.
    /// </summary>
    class Web
    {
        private static Semaphore _pool = new Semaphore(5, 5);

        public static Task<string> DownloadStringTaskAsync(string url, int maximumRetries = 0)
        {
            return Task.Factory.StartNew<string>(() =>
            {
                int failCount = 0;
                string result = null;
                bool success = false;
                while (!success && failCount < maximumRetries)
                {
                    _pool.WaitOne();
                    try
                    {
                        using (WebClient client = GetClient())
                        {
                            result = client.DownloadString(url);
                            success = true;
                        }
                    }
                    catch (Exception e)
                    {
                        failCount++;
                        Console.WriteLine("Request failed: {0}", e.Message);
                    }
                    finally
                    {
                        _pool.Release();
                    }
                }
                return result;
            });
        }

        public static string DownloadString(string url, int maximumRetries = 0)
        {
            int failCount = 0;
            string result = null;
            bool success = false;
            while (!success && failCount < maximumRetries)
            {
                _pool.WaitOne();
                try
                {
                    using (WebClient client = GetClient())
                    {
                        result = client.DownloadString(url);
                        success = true;
                    }
                }
                catch (Exception e)
                {
                    failCount++;
                    Console.WriteLine("Request failed: {0}", e.Message);
                }
                finally
                {
                    _pool.Release();
                }
            }
            return result;
        }

        public static bool DownloadFile(string url, string pathName, int maximumRetries = 0)
        {
            int failCount = 0;
            bool success = false;
            while (!success && failCount < maximumRetries)
            {
                _pool.WaitOne();
                try
                {
                    using (WebClient client = GetClient())
                    {
                        client.DownloadFile(url, pathName);
                        FileInfo fi = new FileInfo(pathName);
                        if (fi.Length > 0)
                            success = true;
                    }
                }
                catch (Exception e)
                {
                    failCount++;
                    Console.WriteLine("Request failed: {0}", e.Message);
                }
                finally
                {
                    _pool.Release();
                }
            }
            return success;
        }

        private static WebClient GetClient()
        {
            WebClient client = new WebClient();
            client.Encoding = Encoding.UTF8;
            client.Headers.Add(HttpRequestHeader.UserAgent, "Mozilla/5.0 (Windows NT 6.1; WOW64; rv:37.0) Gecko/20100101 Firefox/37.0");
            return client;
        }

    }
}
