using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Net;
using System.Text.RegularExpressions;

namespace Picassa
{
    class Yuppo
    {
        private static int NUMBER_OF_TRIES = 5;

        private static Regex reProductName = new Regex("<span id=\"albumtitle\" class=\"albumOwner\">\\s*([^<]+)</span>");
        private static Regex rePhotos = new Regex("<img src=\"([^\"]+)\" width=\"75\" height=\"75\" alt=\"([^\"]+)\" class=\"Photo\" />");
        private static Regex reNext = new Regex("<a class=\"nextprev\" href=\"([^\"]+)\">Next</a>");

        private static Uri UpgradeUri(String uri)
        {
            UriBuilder builder = new UriBuilder(uri);

            string queryToAppend = "style=thumbnail";

            if (builder.Query != null && builder.Query.Length > 1)
                builder.Query = builder.Query.Substring(1) + "&" + queryToAppend;
            else
                builder.Query = queryToAppend;
            return builder.Uri;
        }

        public static PhotoData GetPhotoData(Photo photo)
        {
            using (WebClient client = new WebClient())
            {
                PhotoData data = new PhotoData()
                {
                    Data = DownloadData(client, new Uri(photo.Url), NUMBER_OF_TRIES),
                    Mime = client.ResponseHeaders["Content-Type"]
                };
                return data;
            }
        }

        public static async Task<Product> ReadProductTaskAsync(string url)
        {
            using (WebClient client = new WebClient())
            {
                client.Encoding = Encoding.UTF8;
                client.Headers.Add("Accept-Language", "en-US,en;q=0.5");

                String content = await DownloadStringTaskAsync(client, UpgradeUri(url), NUMBER_OF_TRIES);
                
                Product prod = new Product();
                Match m1 = reProductName.Match(content);
                if (m1.Success)
                {
                    prod.Name = m1.Groups[1].Value;
                }
                else
                {
                    throw new Exception("Missing product name");
                }

                Match mNext = null;
                do
                {
                    // read photos
                    MatchCollection mc = rePhotos.Matches(content);
                    foreach (Match m2 in mc)
                    {
                        Photo photo = new Photo()
                        {
                            Url = m2.Groups[1].Value.Replace("square.jpg", "big.jpg"),
                            Name = m2.Groups[2].Value
                        };
                        prod.Photos.Add(photo);
                    }

                    // check existence of the next page
                    mNext = reNext.Match(content);
                    if (mNext.Success)
                    {
                        // fetch contents of the next page
                        content = await DownloadStringTaskAsync(client, UpgradeUri("http://v.yupoo.com" + mNext.Groups[1].Value), NUMBER_OF_TRIES);
                    }
                } while (mNext.Success);

                return prod;
            }
        }

        public static byte[] DownloadData(WebClient client, Uri uri, int tries)
        {
            while (tries-- > 0)
            {
                try
                {
                    return client.DownloadData(uri);
                }
                catch
                {
                    if (tries == 0) throw;
                }
            }
            throw new Exception("Wrong 'return' clause...");
        }

        public static async Task<String> DownloadStringTaskAsync(WebClient client, Uri uri, int tries)
        {
            while (tries-- > 0)
            {
                try
                {
                    return await client.DownloadStringTaskAsync(uri);
                }
                catch
                {
                    if (tries == 0) throw;
                }
            }
            throw new Exception("Wrong 'return' clause...");
        }

    }

    public class Product
    {
        public string Name { get; set; }
        public string AlbumName { get; set; }

        private List<Photo> photos = new List<Photo>();

        public List<Photo> Photos
        {
            get { return photos; }
        }
    }

    public class Photo
    {
        public string Name { get; set; }
        public string Url { get; set; }
    }

    public class PhotoData
    {
        public string Mime { get; set; }
        public byte[] Data { get; set; }
    }
}
