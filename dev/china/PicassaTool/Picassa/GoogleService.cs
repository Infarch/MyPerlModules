using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.IO;

using Google.GData.Client;
using Google.GData.Photos;
using Google.Picasa;


namespace Picassa
{
    public class GoogleService
    {
        static string AppName = "PicassaTool";

        string username;
        PicasaService service;
        Dictionary<string, Album> cache = new Dictionary<string, Album>();

        public GoogleService(string username, string password)
        {
            // init the service
            this.username = username;
            service = new PicasaService(AppName);
            service.setUserCredentials(username, password);

            // cache albums
            AlbumQuery query = new AlbumQuery(PicasaQuery.CreatePicasaUri(username));
            PicasaFeed feed = service.Query(query);
            foreach (PicasaEntry entry in feed.Entries)
            {
                Album a = new Album();
                a.AtomEntry = entry;
                cache[a.Title] = a;
            }
        }

        public void AddPhoto(string album, Photo photo, PhotoData data)
        {
            Album a = GetAlbum(album);
            AddPhoto(a, photo, data);
        }

        public void AddPhoto(Album album, Photo photo, PhotoData data)
        {
            Uri postUri = new Uri(PicasaQuery.CreatePicasaUri(username, album.Id));
            using (Stream s = new MemoryStream(data.Data))
            {
                PicasaEntry newentry = (PicasaEntry)service.Insert(postUri, s, data.Mime, photo.Name);
            }
        }

        public Album GetAlbum(string album)
        {
            if (cache.ContainsKey(album))
                return cache[album];

            Album a = new Album();
            a.Title = album;
            a.Access = "public";
            Uri feedUri = new Uri(PicasaQuery.CreatePicasaUri(username));
            a.AtomEntry = (PicasaEntry)service.Insert(feedUri, a.AtomEntry);
            cache[album] = a;
            return a;
        }

    }
}
