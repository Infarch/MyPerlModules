using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.IO;
using System.Net;
using System.Threading;

namespace ZapposLeech
{
    enum DownloadResult{Ok, NotFound, Error};

    class Web
    {
        private const int WEBLIMIT = 5;

        private static Encoding encoding = Encoding.UTF8;

        // limited concurrency
        private static Semaphore semPages = new Semaphore(WEBLIMIT, WEBLIMIT);
        private static Semaphore semFiles = new Semaphore(WEBLIMIT, WEBLIMIT);

        private static HttpWebRequest PrepareRequest(Uri uri)
        {
            var request = (HttpWebRequest)WebRequest.Create(uri);
            request.Accept = "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8";
            request.UserAgent = "Mozilla/5.0 (Windows NT 6.1; rv:18.0) Gecko/20100101 Firefox/18.0";
            request.Referer = "http://www.zappos.com/";
            request.Host = "www.zappos.com";
            request.Timeout = 15000;
            request.AllowAutoRedirect = true;

            return request;
        }

        public static string GetContent(Uri uri)
        {
            string content = null;
            
            semPages.WaitOne();

            try
            {
                HttpWebResponse response = (HttpWebResponse)PrepareRequest(uri).GetResponse();
                try
                {
                    Stream receiveStream = response.GetResponseStream();
                    TextReader readStream = new StreamReader(receiveStream, encoding);
                    content = readStream.ReadToEnd();
                    readStream.Close();
                }
                catch (Exception) { }
                response.Close();
            }
            catch (Exception) { }

            semPages.Release();

            return content;
        }

        public static DownloadResult GetFile(Uri uri, string filename)
        {
            DownloadResult dr = DownloadResult.Ok;
            semFiles.WaitOne();
            try
            {
                HttpWebResponse response = (HttpWebResponse)PrepareRequest(uri).GetResponse();
                Stream s = response.GetResponseStream();
                FileStream fs = new FileStream(filename, FileMode.Create, FileAccess.Write, FileShare.ReadWrite);

                byte[] read = new byte[4096];
                int count = s.Read(read, 0, read.Length);
                while (count > 0)
                {
                    fs.Write(read, 0, count);
                    count = s.Read(read, 0, read.Length);
                }

                fs.Close();
                s.Close();
                response.Close();
            }
            catch (WebException we)
            {
                if (we.Status == WebExceptionStatus.ProtocolError)
                {
                    dr = DownloadResult.NotFound;
                }
                else
                {
                    dr = DownloadResult.Error;
                }
            }
            catch (Exception)
            {
                dr = DownloadResult.Error;
            }
            semFiles.Release();
            return dr;
        }

    }
}
