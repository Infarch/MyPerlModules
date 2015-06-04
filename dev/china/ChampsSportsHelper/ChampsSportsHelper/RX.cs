using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

using System.Text.RegularExpressions;

namespace ChampsSportsHelper
{
    /// <summary>
    /// Implements various operations need Regexp engine
    /// </summary>
    class RX
    {
        static Regex reModels = new Regex("^E3F920DF-E1E6-4A94-827C-C10BF3ECBEAB:(.+)$");
        static Regex reModelInfo = new Regex("^var model = (.+);$", RegexOptions.Multiline);
        static Regex reStylesInfo = new Regex("^var styles = (.+);$", RegexOptions.Multiline);
        static Regex reStyleWidth = new Regex("<span class='attType_width'>(.*?)</span>");
        static Regex reImages = new Regex("\\{\"IMAGE_SET\":\"([^\"]+)\"");
        static Regex reMetaImg = new Regex("<meta property=\"og\\:image\" content=\"([^\"]+)\" />");

        public static string ExtractModelInfo(string page)
        {
            Match m = reModelInfo.Match(page);
            if (!m.Success)
                throw new Exception("Model data is missing");
            return m.Groups[1].Value;
        }

        public static string ExtractStylesInfo(string page)
        {
            Match m = reStylesInfo.Match(page);
            if (!m.Success)
                throw new Exception("Styles data is missing");
            return m.Groups[1].Value;
        }

        public static string ExtractWidth(string raw)
        {
            Match mWidth = reStyleWidth.Match(raw);
            if (mWidth.Success)
            {
                return mWidth.Groups[1].Value.Replace("Width - ", String.Empty);
            }
            return String.Empty;
        }

        public static string ExtractMetaImage(string page)
        {
            // extract a preview image reference
            Match m = reMetaImg.Match(page);
            if (m.Success)
            {
                return "http:" + m.Groups[1].Value;
            }
            return String.Empty;
        }

        public static IEnumerable<string> ExtractImages(string data)
        {
            HashSet<string> uniques = new HashSet<string>();
            List<string> images = new List<string>();

            Match m = reImages.Match(data);
            if (m.Success)
            {
                string imgRawInfo = m.Groups[1].Value;
                string[] parts = imgRawInfo.Split(new Char[] { ';', ',' });
                foreach (string part in parts)
                {
                    if (!uniques.Contains(part))
                    {
                        uniques.Add(part);
                        images.Add(part);
                    }
                }
            }

            return images;
        }

        public static IEnumerable<ProductModel> ExtractModels(string text)
        {
            List<ProductModel> models = new List<ProductModel>();

            Match m = reModels.Match(text);
            if (m.Success)
            {
                string allSubmittedModels = m.Groups[1].Value;
                var modelDescriptors = allSubmittedModels.Split(new char[] { ';' });
                foreach(var modelDescriptor in modelDescriptors)
                {

                    string[] modelDescriptorParts = modelDescriptor.Split(new char[] { '|' });
                    if (modelDescriptorParts.Length == 2)
                    {
                        int modelNumber = 0;
                        if (Int32.TryParse(modelDescriptorParts[0], out modelNumber))
                        {
                            ProductModel prodModel = new ProductModel(modelNumber, modelDescriptorParts[1]);
                            models.Add(prodModel);
                        }
                        else
                        {
                            throw new Exception(String.Format("{0} coul not be parsed as a integer", modelDescriptor));
                        }

                    }
                    else
                    {
                        throw new Exception(String.Format("Cannot use the '{0}' as a model's descriptor", modelDescriptor));
                    }
                }

            }

            return models;
        }
    }
}
