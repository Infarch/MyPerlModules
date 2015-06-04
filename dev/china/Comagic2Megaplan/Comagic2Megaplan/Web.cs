using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.IO;
using System.Net;

namespace Comagic2Megaplan
{
    class Web
    {

        public static string DownloadFileHttp(string link, string path)
        {
            WebClient wc = new WebClient();
            var data = wc.DownloadData(link);
            string fileName = "call.mp3";
            
            // Try to extract the filename from the Content-Disposition header
            if (!String.IsNullOrEmpty(wc.ResponseHeaders["Content-Disposition"]))
            {
                fileName = wc.ResponseHeaders["Content-Disposition"].Substring(wc.ResponseHeaders["Content-Disposition"].IndexOf("filename=") + 10).Replace("\"", "");
            }

            string pathName = Path.Combine(path, fileName);

            using (FileStream ws = new FileStream(pathName, FileMode.Create))
            {
                ws.Write(data, 0, data.Length);
            }
        
            return pathName;
        }

        public static void DownloadFileFtp(string link, string destinationFile)
        {
            FtpWebRequest request = (FtpWebRequest)WebRequest.Create(link);
            request.Method = WebRequestMethods.Ftp.DownloadFile;
            request.UseBinary = true;
            request.UsePassive = true;

            using (FtpWebResponse response = (FtpWebResponse)request.GetResponse())
            using (Stream rs = response.GetResponseStream())
            using (FileStream ws = new FileStream(destinationFile, FileMode.Create))
            {
                byte[] buffer = new byte[2048];
                int bytesRead = rs.Read(buffer, 0, buffer.Length);
                while (bytesRead > 0)
                {
                    ws.Write(buffer, 0, bytesRead);
                    bytesRead = rs.Read(buffer, 0, buffer.Length);
                }
            }

        }

    }
}
