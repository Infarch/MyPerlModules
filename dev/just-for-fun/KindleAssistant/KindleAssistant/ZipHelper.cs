using System;
using System.IO;
using System.Text;
using System.IO.Compression;


namespace KindleAssistant
{
    public class ZipHelper
    {

        public static Stream MakeZipStream(String book, String name)
        {
            MemoryStream ms = new MemoryStream();
            ZipStorer zip = ZipStorer.Create(ms, "Created automatically");
            MemoryStream readme = new MemoryStream(System.Text.Encoding.UTF8.GetBytes(book));
            zip.AddStream(ZipStorer.Compression.Deflate, name, readme, DateTime.Now, "A file");
            readme.Close();
            zip.Close(false);
            
            ms.Position = 0;
            return ms;
        }

    }
}
