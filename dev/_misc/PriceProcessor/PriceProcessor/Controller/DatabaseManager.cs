using System;
using System.Linq;
using System.Data.SqlClient;
using System.Data.EntityClient;
using System.Collections.Generic;
using System.Data.Objects;
using System.Threading;

using FileHelpers;

using PriceProcessor.Model;

namespace PriceProcessor.Controller
{
    class DatabaseManager
    {
        private const byte APPROVAL_STATUS_NEW = 1;
        private const byte APPROVAL_STATUS_APPROVED = 2;
        private const byte APPROVAL_STATUS_REJECTED = 3;

        private const string APPROVAL_COMMAND_UNDEFINED = "";
        private const string APPROVAL_COMMAND_APPROVE = "1";
        private const string APPROVAL_COMMAND_REJECT = "0";


        string db_name;

        public DatabaseManager(string db_name)
        {
            this.db_name = db_name;
        }

        EntityConnection GetEntityConnection()
        {
            EntityConnectionStringBuilder ee = new EntityConnectionStringBuilder();
            ee.Provider = "System.Data.SQLite";
            ee.Metadata = @"res://*/Model.Database.csdl|res://*/Model.Database.ssdl|res://*/Model.Database.msl";
            ee.ProviderConnectionString = String.Format(@"data source={0};", db_name);
            return new EntityConnection(ee.ConnectionString);
        }

        public DatabaseContext GetContext()
        {
            return new DatabaseContext(GetEntityConnection());
        }

        public long GetPendingTasksCount()
        {
            long i = 0;
            using (DatabaseContext context = GetContext())
            {
                foreach (int k in context.ExecuteStoreQuery<int>("select count(*) from WebTask where Status={0}", Member.STATUS_NEW))
                {
                    i = k;
                }
            }
            return i;
        }

        public Member[] GetPendingTasks(int limit)
        {
            List<Member> members = new List<Member>();

            using (DatabaseContext context = GetContext())
            {
                
                var query = context.WebTasks.Where("it.Status=@st", new ObjectParameter("st", Member.STATUS_NEW))
                    .OrderBy("it.Errors")
                    .Top("@limit", new ObjectParameter("limit", limit));

                foreach (WebTask task in query)
                {
                    Member m = new Member
                    {
                        Id = task.Id,
                        ProductId = task.ProductId,
                        EngineId = task.EngineId,
                        Url = task.Url,
                        Errors = task.Errors,
                        Status = task.Status,
                        TaskType = task.TaskType
                    };
                    members.Add(m);
                }
            }
            return members.ToArray();
        }

        public void InsertApprovalItems(DatabaseContext context, Member member, SearchItem[] items)
        {
            foreach (SearchItem item in items)
            {
                ApprovalItem ap = new ApprovalItem()
                {
                    EngineId = member.EngineId,
                    ProductId = member.ProductId,
                    Url = item.Url,
                    Name = item.Name,
                    Price = item.Price,
                    Status = APPROVAL_STATUS_NEW
                };
                context.AddToApprovalItems(ap);
            }
        }

        public void UpdateEngines(string[] names, CancellationToken token)
        {
            using (DatabaseContext context = GetContext())
            {
                int i = 0;
                foreach (string name in names)
                {
                    Console.WriteLine("Check engine {0}", name);
                    if (token.IsCancellationRequested) break;
                    // exists?
                    if (!context.Engines.Any(o => o.Name == name))
                    {
                        Engine e = new Engine()
                        {
                            Name = name
                        };
                        context.AddToEngines(e);
                        Console.WriteLine("Added engine {0}", name);
                        i++;
                    }
                }
                if (i > 0) context.SaveChanges();
            }
        }

        public void LoadNewProducts(string fileName, CancellationToken token)
        {
            using (DatabaseContext context = GetContext())
            {
                FileHelperAsyncEngine<CsvNewProduct> engine = new FileHelperAsyncEngine<CsvNewProduct>();
                engine.BeginReadFile(fileName);
                int i = 0;
                foreach (CsvNewProduct np in engine)
                {
                    if (token.IsCancellationRequested) break;
                    // check existence of the product
                    // using its code
                    Console.WriteLine("Checking product {0}...", np.ProductCode);
                    if (!context.Products.Any((o) => o.ProductCode == np.ProductCode))
                    {
                        Product p = new Product()
                        {
                            Name = np.ProductName,
                            ProductCode = np.ProductCode
                        };
                        context.AddToProducts(p);
                        Console.WriteLine("Added product {0}", np.ProductCode);
                        i++;
                    }
                }
                engine.Close();
                if (i > 0) context.SaveChanges();
                Console.WriteLine("Added {0} new products", i);
            }
        }

        public void CreateSearchTasks(CancellationToken token)
        {
            using (DatabaseContext context = GetContext())
            {
                int i = 0;
                foreach (ViewNewSearch w in context.ViewNewSearches)
                {
                    if (token.IsCancellationRequested) break;
                    WebTask task = new WebTask()
                    {
                        ProductId = w.ProductId,
                        EngineId = w.EngineId,
                        TaskType = Member.TASKTYPE_SEARCH,
                        Url = SearchEngineManager.GetSearchUrl(w.EngineId, w.ProductName),
                        Status = Member.STATUS_NEW
                    };
                    context.AddToWebTasks(task);
                    i++;
                }
                if (i > 0 && !token.IsCancellationRequested) context.SaveChanges();
            }
        }

        public void SyncEngines(SearchEngine[] engines, CancellationToken token)
        {
            using (DatabaseContext context = GetContext())
            {
                int i = 0;
                foreach (SearchEngine engine in engines)
                {
                    if (token.IsCancellationRequested) break;
                    Console.WriteLine("Check engine {0}", engine.Name);

                    // check existence
                    if (context.Engines.Any(o => o.Name == engine.Name))
                    {
                        // exists - update ID
                        engine.Id = context.Engines.First(o => o.Name == engine.Name).Id;
                        Console.WriteLine("Engine {0} ({1}) already exists", engine.Name, engine.Id);
                    }
                    else
                    {
                        // does not exist - insert
                        Engine e = new Engine()
                        {
                            Name = engine.Name
                        };
                        context.AddToEngines(e);
                        Console.WriteLine("Added engine {0}", engine.Name);
                        i++;
                    }

                }
                if (i > 0) context.SaveChanges();
            }
        }

        public void ExportApprovalList(string fileName, CancellationToken token)
        {
            using (DatabaseContext context = GetContext())
            {
                // init engine
                FileHelperAsyncEngine<CsvApprovalItem> engine = new FileHelperAsyncEngine<CsvApprovalItem>() { HeaderText = CsvApprovalItem.HeaderLine };
                engine.BeginWriteFile(fileName);

                // look for approval items
                var query = context.ViewApprovalLists.Where("it.Status=@st", new ObjectParameter("st", APPROVAL_STATUS_NEW));
                foreach (ViewApprovalList item in query)
                {
                    if (token.IsCancellationRequested) break;
                    engine.WriteNext(new CsvApprovalItem()
                    {
                        ItemID = item.Id,
                        EngineName = item.EngineName,
                        ProductName = item.SearchName,
                        FoundName = item.Name,
                        URL = item.Url,
                        Price = item.Price,
                        Command = APPROVAL_COMMAND_UNDEFINED
                    });
                }
                engine.Close();
            }
        }

        public void ImportApprovalList(string p, CancellationToken token)
        {
            using (DatabaseContext context = GetContext())
            {
                FileHelperAsyncEngine<CsvApprovalItem> engine = new FileHelperAsyncEngine<CsvApprovalItem>();
                engine.BeginReadFile(p);

                foreach (CsvApprovalItem item in engine)
                {
                    
                    if(token.IsCancellationRequested) break;

                    // check approval status
                    if (item.Command == APPROVAL_COMMAND_APPROVE || item.Command == APPROVAL_COMMAND_REJECT)
                    {
                        // check existence of an unapproved yet record
                        ApprovalItem ai = context.ApprovalItems.Where("it.Id=@id and it.Status=@st", 
                            new ObjectParameter("id", item.ItemID),
                            new ObjectParameter("st", APPROVAL_STATUS_NEW)).SingleOrDefault();
                        if (ai != null)
                        {
                            Console.WriteLine("Updating approval item {0}", ai.Id);
                            // apply changes. note that url could also be changed
                            ai.Status = item.Command == APPROVAL_COMMAND_APPROVE ? APPROVAL_STATUS_APPROVED : APPROVAL_STATUS_REJECTED;
                            if (!String.IsNullOrWhiteSpace(item.URL) && item.URL != ai.Url) ai.Url = item.URL;
                        }
                    }
                }
                engine.Close();
                // save changes
                if(!token.IsCancellationRequested) context.SaveChanges();
            }
        }

        internal void CreateUpdateTasks(CancellationToken token)
        {
            using (DatabaseContext context = GetContext())
            {
                int i = 0;
                foreach (var w in context.ViewUpdates)
                {
                    if (token.IsCancellationRequested) break;
                    WebTask task = new WebTask()
                    {
                        ProductId = w.ProductId,
                        EngineId = w.EngineId,
                        TaskType = Member.TASKTYPE_UPDATE_INFO,
                        Url = w.Url,
                        Status = Member.STATUS_NEW
                    };
                    context.AddToWebTasks(task);
                    i++;
                }
                if (i > 0 && !token.IsCancellationRequested) context.SaveChanges();
            }

        }

        public void InsertPriceInfo(long ProductId, long EngineId, PriceInfo pi)
        {
            using (DatabaseContext context = GetContext())
            {
                ProductPriceInfo ppi = new ProductPriceInfo()
                {
                    ProductId = ProductId,
                    EngineId = EngineId,
                    Price = pi.Price,
                    InStock = pi.InStock,
                    DateOfCheck = DateTime.Now
                };
                context.AddToProductPriceInfoes(ppi);
                context.SaveChanges();
            }
        }
    }
}
