using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.IO;

namespace ChampsSportsHelper
{
    class ModelsCollection : IEnumerable<ProductModel>
    {
        string dataFile;
        Object stopLocker = new Object();
        HashSet<int> stopList = new HashSet<int>();
        List<ProductModel> models = new List<ProductModel>();

        public int Count
        {
            get { return models.Count; }
        }

        public int CountFailed
        {
            get { return models.Count(model => model.Status == ProductModel.ModelStatus.Failed); }
        }

        public int CountProcessed
        {
            get { return models.Count(model => model.Status == ProductModel.ModelStatus.Processed); }
        }
        
        public IEnumerator<ProductModel> GetEnumerator()
        {
            return models.GetEnumerator();
        }

        System.Collections.IEnumerator System.Collections.IEnumerable.GetEnumerator()
        {
            return this.GetEnumerator();
        }

        /// <summary>
        /// Datafile is a text file where each line contains a model number.
        /// The class reads the file in constructor and does not allow to add models which already exist in the file.
        /// Before destruction, the class updates the list.
        /// </summary>
        /// <param name="dataFile"></param>
        public ModelsCollection(string dataFile)
        {
            this.dataFile = dataFile;
            if (File.Exists(dataFile))
            {
                string[] lines = File.ReadAllLines(dataFile);
                foreach (string line in lines)
                {
                    int modelNumber = 0;
                    if (Int32.TryParse(line, out modelNumber))
                    {
                        stopList.Add(modelNumber);
                    }
                }
            }
        }

        public bool TryAdd(ProductModel pm)
        {
            bool added = false;
            lock (stopLocker)
            {
                added = stopList.Add(pm.Number);
            }
            if (added)
                models.Add(pm);
            return added;
        }

        public void Clear()
        {
            models.Clear();
        }

        public void Flush()
        {
            File.WriteAllLines(dataFile, stopList.Select(x => { return x.ToString(); }));
        }

        /// <summary>
        /// Destructor: calls Flush before exit
        /// </summary>
        ~ModelsCollection()
        {
            Flush();
        }

    }
}
