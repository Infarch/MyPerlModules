using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Threading;
using System.Collections.Concurrent;

namespace ChampsSportsHelper
{
    class SiteProcessor
    {

        private static Queue<ProductModel> modelsQueue;
        private static Thread worker;


        static SiteProcessor()
        {
            modelsQueue = new Queue<ProductModel>();
            worker = new Thread(DoWork);
            worker.IsBackground = true;
            worker.Start();
        }

        public static void Ping()
        {
            Console.WriteLine("pong");
        }

        public static void ProcessModelsAsync(IEnumerable<ProductModel> models)
        {
            foreach (var model in models)
                modelsQueue.Enqueue(model);
        }

        public static void ProcessModelAsync(ProductModel model)
        {
            modelsQueue.Enqueue(model);
        }

        private static void DoWork()
        {
            int count = 0;
            while (true)
            {

                if (modelsQueue.Count > 0)
                {
                    try
                    {
                        var model = modelsQueue.Dequeue();
                        count++;
                        Console.WriteLine("Dequeued a product model");
                        try
                        {
                            model.Process();
                        }
                        catch(Exception e)
                        {
                            model.Status = ProductModel.ModelStatus.Failed;
                            Console.WriteLine(e.Message);
                        }
                    }
                    catch (InvalidOperationException) { }
                }
                else
                {
                    Thread.Sleep(200);
                }
                
            }
            
        }

    }
}
