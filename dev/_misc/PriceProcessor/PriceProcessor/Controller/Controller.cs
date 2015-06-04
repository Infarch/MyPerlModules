using System;
using System.Collections.Generic;
using System.Collections.Concurrent;
using System.Threading;
using System.Threading.Tasks;
using System.Text;
using System.Net;

using DBH = PriceProcessor.Model.DatabaseContext;

namespace PriceProcessor.Controller
{
    class ControllerSummary
    {
        long pendingTasksCount;

        public long PendingTasksCount
        {
            get { return pendingTasksCount; }
            set { pendingTasksCount = value; }
        }
    }
    class ControllerActionEventArgs : EventArgs
    {
        bool success;
        string message;
        ControllerSummary summary;

        public ControllerSummary Summary
        {
            get { return summary; }
            set { summary = value; }
        }
        public string Message
        {
            get { return message; }
            set { message = value; }
        }
        public bool Success
        {
            get { return success; }
            set { success = value; }
        }
    }

    class Controller
    {
        // internal variables
        string db_path;
        bool initialized = false;
        DatabaseManager dbmanager;
        CancellationTokenSource cancelFactory;
        TaskScheduler scheduler;

        long taskCount = 0;

        public bool IsBusy
        {
            get { return Interlocked.Read(ref taskCount) > 0; }
        }

        // delegates and events
        public delegate void ControllerActionComplete(Object sender, ControllerActionEventArgs e);

        public event ControllerActionComplete OnInitComplete;
        public event ControllerActionComplete OnProcessTasksComplete;
        public event ControllerActionComplete OnLoadProductsComplete;
        public event ControllerActionComplete OnSearchProductsComplete;
        public event ControllerActionComplete OnExportApprovalListComplete;
        public event ControllerActionComplete OnImportApprovalListComplete;
        public event ControllerActionComplete OnUpdatePriceComplete;

        private void FireEvent(ControllerActionComplete handler, ControllerActionEventArgs e)
        {
            if (handler != null) handler(this, e);
        }


        // make sure that we have ONLY ONE INSTANCE of the Controller
        private static Controller instance;
        //private Controller() { }
        private Controller(string db_path)
        {
            this.db_path = db_path;
            cancelFactory = new CancellationTokenSource();
            scheduler = TaskScheduler.FromCurrentSynchronizationContext();
        }
        public static Controller GetController(string database_path)
        {
            if (instance == null) instance = new Controller(database_path);
            return instance;
        }

        
        
        public void InitAsync()
        {
            Console.WriteLine("Initializig Controller");
            ScheduleAction(Init, OnInitComplete);
        }
        void Init()
        {
            Console.WriteLine("Initializig Controller in background");
            CancellationToken token = cancelFactory.Token;
            
            // create an instance of database manager
            token.ThrowIfCancellationRequested();
            dbmanager = new DatabaseManager(db_path);
            // initialize search engines
            token.ThrowIfCancellationRequested();
            SearchEngine[] engines = SearchEngineManager.GetAllEngines();
            dbmanager.SyncEngines(engines, token);
            token.ThrowIfCancellationRequested();
            initialized = true;
        }

        public void ProcessPendingTasksAsync()
        {
            CheckInit();
            Console.WriteLine("Process pending tasks");
            ScheduleAction(ProcessPendingTasks, OnProcessTasksComplete);
        }
        void ProcessPendingTasks()
        {
            CancellationToken token = cancelFactory.Token;
            ProcessPendingTasks(token);
        }
        void ProcessPendingTasks(CancellationToken token)
        {
            int taskcount = 8;
            int fetch_limit = 1000;
            Member[] news = dbmanager.GetPendingTasks(fetch_limit);
            ConcurrentQueue<Member> queue = new ConcurrentQueue<Member>();
            Action action = () =>
            {
                using (WebClient client = new System.Net.WebClient())
                {
                    // process members
                    using (DBH dbh = dbmanager.GetContext())
                    {
                        Member member = null;
                        while (queue.TryDequeue(out member) && !token.IsCancellationRequested)
                        {
                            member.Process(dbh, dbmanager, client);
                        }
                    }
                }
            };
            while (news.Length > 0)
            {
                Console.WriteLine("Fetched {0} new members", news.Length);
                // populate queue
                foreach (Member m in news) queue.Enqueue(m);

                // start X tasks for processing the queue
                List<Task> tasks = new List<Task>();
                for (int i = 0; i < taskcount; i++)
                {
                    Task t = Task.Factory.StartNew(action);
                    tasks.Add(t);
                }
                // wait for finish
                foreach (Task t in tasks) t.Wait();
                // check token
                token.ThrowIfCancellationRequested();
                // get another bundle of members
                news = dbmanager.GetPendingTasks(fetch_limit);
            }
            token.ThrowIfCancellationRequested();
        }

        public void LoadProductsAsync(string fileName)
        {
            CheckInit();
            Console.WriteLine("Start loading products from CSV file: {0}", fileName);
            ScheduleAction(LoadProducts, fileName, OnLoadProductsComplete);
        }
        void LoadProducts(Object fileName)
        {
            CancellationToken token = cancelFactory.Token;
            dbmanager.LoadNewProducts(fileName as string, token);
            token.ThrowIfCancellationRequested();
        }

        public void SearchProductsAsync()
        {
            CheckInit();
            Console.WriteLine("Start searching products");
            ScheduleAction(SearchProducts, OnSearchProductsComplete);
        }
        void SearchProducts()
        {
            CancellationToken token = cancelFactory.Token;
            dbmanager.CreateSearchTasks(token);
            token.ThrowIfCancellationRequested();
            ProcessPendingTasks(token);
            token.ThrowIfCancellationRequested();
        }

        public void ExportApprovalListAsync(string fileName)
        {
            CheckInit();
            Console.WriteLine("Start exporting approval list into {0}", fileName);
            ScheduleAction(ExportApprovalList, fileName, OnExportApprovalListComplete);
        }
        void ExportApprovalList(Object fileName)
        {
            CancellationToken token = cancelFactory.Token;
            dbmanager.ExportApprovalList(fileName as string, token);
            token.ThrowIfCancellationRequested();
        }

        public void ImportApprovalListAsync(string fileName)
        {
            CheckInit();
            Console.WriteLine("Start importing approval list from {0}", fileName);
            ScheduleAction(ImportApprovalList, fileName, OnImportApprovalListComplete);
        }
        void ImportApprovalList(Object fileName)
        {
            CancellationToken token = cancelFactory.Token;
            dbmanager.ImportApprovalList(fileName as string, token);
            token.ThrowIfCancellationRequested();
        }

        public void UpdatePricesAsync()
        {
            CheckInit();
            Console.WriteLine("Start updating prices");
            ScheduleAction(UpdatePrices, OnUpdatePriceComplete);
        }

        void UpdatePrices()
        {
            CancellationToken token = cancelFactory.Token;

            // create tasks
            dbmanager.CreateUpdateTasks(token);
            token.ThrowIfCancellationRequested();

            // process tasks
            ProcessPendingTasks(token);

            token.ThrowIfCancellationRequested();
        }



        void ScheduleAction(Action action, ControllerActionComplete handler)
        {
            Interlocked.Increment(ref taskCount);
            BindHandler(Task.Factory.StartNew(action, cancelFactory.Token), handler);
        }
        void ScheduleAction(Action<Object> action, Object param, ControllerActionComplete handler)
        {
            Interlocked.Increment(ref taskCount);
            BindHandler(Task.Factory.StartNew(action, param, cancelFactory.Token), handler);
        }
        void BindHandler(Task task, ControllerActionComplete handler)
        {
            if (handler != null)
            {
                task.ContinueWith(taskresult =>
                {
                    Interlocked.Decrement(ref taskCount);
                    handler(this, BuildEventArgs());
                }, CancellationToken.None, TaskContinuationOptions.OnlyOnRanToCompletion, scheduler);

                task.ContinueWith(taskresult =>
                {
                    Interlocked.Decrement(ref taskCount);
                    handler(this, BuildEventArgs(taskresult.Exception));
                }, CancellationToken.None, TaskContinuationOptions.OnlyOnFaulted, scheduler);

                task.ContinueWith(taskresult =>
                {
                    Interlocked.Decrement(ref taskCount);
                    Console.WriteLine("Controller was cancelled");
                    // no postback
                }, CancellationToken.None, TaskContinuationOptions.OnlyOnCanceled, scheduler);

            }
        }
        ControllerActionEventArgs BuildEventArgs()
        {
            try
            {
                ControllerActionEventArgs evt = new ControllerActionEventArgs();
                evt.Summary = GetSummary();
                evt.Success = true;
                return evt;
            }
            catch (Exception e)
            {
                return BuildEventArgs(e);
            }
        }
        ControllerActionEventArgs BuildEventArgs(Exception e)
        {
            ControllerActionEventArgs evt = new ControllerActionEventArgs();
            evt.Message = GetErrorMessage(e);
            return evt;
        }
        string GetErrorMessage(Exception e)
        {
            StringBuilder sb = new StringBuilder(e.Message);
            Exception inner = e.InnerException;
            while (inner != null)
            {
                sb.AppendLine("").Append(inner.Message);
                inner = inner.InnerException;
            }

            return sb.ToString();
        }
        string GetErrorMessage(AggregateException e)
        {
            StringBuilder sb = new StringBuilder("");
            foreach (var inner in e.InnerExceptions)
            {
                sb.AppendLine(inner.Message);
            }
            return sb.ToString();
        }
        ControllerSummary GetSummary()
        {
            ControllerSummary cs = new ControllerSummary
            {
                PendingTasksCount = dbmanager.GetPendingTasksCount()
            };
            return cs;
        }
        void CheckInit()
        {
            if (!initialized) throw new Exception("Object is not initialized");
        }
        public void CancelTasks()
        {
            cancelFactory.Cancel();
        }

    }
}
