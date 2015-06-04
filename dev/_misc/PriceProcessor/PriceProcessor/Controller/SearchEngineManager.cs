using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Net;

using PriceProcessor.Controller.Engines;

namespace PriceProcessor.Controller
{
    class SearchEngineManager
    {
        static List<SearchEngine> engines;
        static SearchEngineManager()
        {
            engines = new List<SearchEngine>();
            engines.Add(new MtOnline());
        }

        public static SearchEngine[] GetAllEngines()
        {
            return engines.ToArray();
        }

        public static SearchEngine GetEngine(long id)
        {
            return engines.Find(o => o.Id == id);
        }

        public static SearchItem[] ExtractSearchItems(long engine_id, string content)
        {
            return GetEngine(engine_id).ExtractSearchItems(content);
        }

        public static Encoding GetEncoding(long EngineId)
        {
            return GetEngine(EngineId).Encoding;
        }

        public static SearchItem[] ExtractSearchItems(Member member)
        {
            return ExtractSearchItems(member.EngineId, member.Content);
        }

        public static string GetSearchUrl(long engineId, string productName)
        {
            return GetEngine(engineId).GetSearchUrl(productName);
        }

        public static PriceInfo ExtractPriceInfo(Member member)
        {
            return GetEngine(member.EngineId).ExtractPriceInfo(member.Content);
        }

    }
}
