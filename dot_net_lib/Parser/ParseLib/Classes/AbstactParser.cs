using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading;
using System.Threading.Tasks;
using System.Net;

using ParseLib.Database;


namespace ParseLib.Classes
{
    public enum MemberStatus { New = 1, InProgress = 2, Done = 3, Failed = 4 }

    public abstract class AbstactParser
    {

        protected const byte ERROR_TRIVIAL = 1;
        protected const byte ERROR_MINOR = 2; // trivial * 2
        protected const byte ERROR_MAJOR = 4; // minor * 2
        protected const byte ERROR_CRITICAL = 8; // you see )
        protected const byte LIMIT_ERROR = 8; // so a critical error breaks a member permanently

        string dbname;
        string servername;
        string cs;
        TaskScheduler scheduler;
        CancellationTokenSource tokenSource;

        int queueLimit = 500;
        bool demoMode;

        public bool DemoMode
        {
            get { return demoMode; }
            set { demoMode = value; }
        }

        public int QueueLimit
        {
            get { return queueLimit; }
            set 
            {
                if (value < 1) throw new ArgumentException("The QueueLimit value must be greater than zero");
                queueLimit = value; 
            }
        }

        bool cancelled;
        bool busy;

        public bool Busy
        {
            get { return busy; }
        }
        public bool Cancelled
        {
            get { return cancelled; }
        }


        public event EventHandler Finished;

        void HandleFinish()
        {
            busy = false;
            if (Finished != null) Finished(this, EventArgs.Empty);
        }

        public void Cancel()
        {
            if (!busy) throw new Exception("Parser is not busy");
            cancelled = true;
            tokenSource.Cancel();
        }

        public void RunAsync()
        {
            if (busy) throw new Exception("Parser is busy");
            busy = true;
            if (tokenSource != null) tokenSource.Dispose();
            tokenSource = new CancellationTokenSource();

            Task.Factory.StartNew(DoWork, TaskCreationOptions.LongRunning)
                .ContinueWith((t) => { HandleFinish(); }, scheduler);
        }

        public AbstactParser(string servername, string dbname)
        {
            this.servername = servername;
            this.dbname = dbname;
            cs = String.Format("metadata=res://*/Database.SmartModel.csdl|res://*/Database.SmartModel.ssdl|res://*/Database.SmartModel.msl;provider=System.Data.SqlClient;provider connection string=\"Data Source={0};Initial Catalog={1};Integrated Security=True;MultipleActiveResultSets=True\"", servername, dbname);
            using (SmartModelContainer context = GetContext())
            {
                if (!context.DatabaseExists()) context.CreateDatabase();
            }
            try
            {
                scheduler = TaskScheduler.FromCurrentSynchronizationContext();
            }
            catch (InvalidOperationException)
            {
                scheduler = TaskScheduler.Default;
            }
        }

        private SmartModelContainer GetContext()
        {
            return new SmartModelContainer(cs);
        }

        private void TaskHandler(Category data)
        {
        
        }

        /// <summary>
        /// The function DOES NOT save changes into database, it just returns true if a meber 
        /// has been successfully processed and the 'save' operation is allowed.
        /// </summary>
        /// <param name="context">EF context</param>
        /// <param name="member">WebResource instance</param>
        /// <returns>true if success, false otherwise</returns>
        public bool TryProcessMember(SmartModelContainer context, WebResource member)
        {
            bool success = false;
            try
            {
                // do all parsing here
                member.Status = (int)MemberStatus.Done;
                HttpWebRequest request = (HttpWebRequest)WebRequest.Create(member.Url);
                request.Headers.Add("Accept-Encoding", "gzip, deflate");
                HttpWebResponse response = (HttpWebResponse)request.GetResponse();

                // use an appropriate web resource handler to process the member

                // allow to commit changes
                success = true;
            }
            catch (Exception e)
            {
                RegisterException(member.Id, e);
            }
            return success;
        }

        public void ProcessMember(int memberId)
        {
            using (SmartModelContainer context = GetContext())
            {
                WebResource member = context.WebResourceSet.First(x => x.Id == memberId);
                if (TryProcessMember(context, member))
                {
                    if (!DemoMode) context.SaveChanges();
                }
            }
            //if (data is Category)
            //{

            //}
            //else
            //{
            //    throw new NotImplementedException(String.Format("The data type {0} is not supported yet.", data.GetType().Name));
            //}
        }

        protected void RegisterException(int memberId, Exception exc)
        {
            using (SmartModelContainer context = GetContext())
            {
                var data = context.WebResourceSet.First(x => x.Id == memberId);
                byte weight = 0;
                if (exc is WebException)
                {
                    weight = ERROR_TRIVIAL;
                }
                else
                {
                    // an unrecognized exception causes the global shutdown of app
                    throw new Exception("Unexpected exeption!", exc);
                }
                data.Errors += weight;
                if (data.Errors < LIMIT_ERROR)
                {
                    // let it be...
                    data.Status = (int)MemberStatus.New;
                }
                else
                {
                    // must die
                    data.Status = (int)MemberStatus.Failed;
                }
                context.SaveChanges();
            }
        }

        protected void ProcessMember(object data)
        {
            ProcessMember((Int32)data);
        }

        private void DoWork()
        {
            CancellationToken token = tokenSource.Token;

            bool hasdata = true;
            while (!token.IsCancellationRequested && hasdata)
            {
                using (SmartModelContainer context = GetContext())
                {
                    var datalist = context.WebResourceSet.Where(x => x.Status == (int)MemberStatus.New).Take(QueueLimit);
                    List<Task> tasks = new List<Task>();
                    foreach (var dataitem in datalist)
                    {
                        Task task = Task.Factory.StartNew(ProcessMember, dataitem.Id, token)
                            .ContinueWith((t) =>
                            {
                                // if a task has failed we stop the entire application
                                tokenSource.Cancel();
                            }, TaskContinuationOptions.OnlyOnFaulted);
                        tasks.Add(task);
                    }
                    hasdata = tasks.Count > 0;
                    try
                    {
                        Task.WaitAll(tasks.ToArray());
                    }
                    catch (Exception) { }
                }
            }
        }
    }
}
