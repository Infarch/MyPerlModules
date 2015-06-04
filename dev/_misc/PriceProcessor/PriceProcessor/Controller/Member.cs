using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading;
using System.Net;

using DBH = PriceProcessor.Model.DatabaseContext;

namespace PriceProcessor.Controller
{
    class Member
    {
        public const int ERROR_LIMIT = 15;
        
        public const int STATUS_NEW = 1;
        public const int STATUS_DONE = 3;
        public const int STATUS_FAILED = 4;

        public const int TASKTYPE_SEARCH = 1;
        public const int TASKTYPE_UPDATE_INFO = 2;

        string content = "";

        long id;
        long engineId;
        long productId;
        string url;
        int taskType;
        int errors;
        int status;

        public int Status
        {
            get { return status; }
            set { status = value; }
        }
        public string Content
        {
            get { return content; }
        }
        public int Errors
        {
            get { return errors; }
            set { errors = value; }
        }
        public int TaskType
        {
            get { return taskType; }
            set { taskType = value; }
        }
        public string Url
        {
            get { return url; }
            set { url = value; }
        }
        public long ProductId
        {
            get { return productId; }
            set { productId = value; }
        }
        public long EngineId
        {
            get { return engineId; }
            set { engineId = value; }
        }
        public long Id
        {
            get { return id; }
            set { id = value; }
        }

        public void Process(DBH dbh, DatabaseManager dbmanager, WebClient client)
        {
            Console.WriteLine("Processing member {0}", Id);
            Status = STATUS_DONE;
            try
            {
                client.Encoding = SearchEngineManager.GetEncoding(EngineId);
                //WebClient client = SearchEngineManager.PrepareWebClient(EngineId);
                content = client.DownloadString(Url);
                switch (TaskType)
                {
                    case TASKTYPE_SEARCH:
                        SearchItem[] slist = SearchEngineManager.ExtractSearchItems(this);
                        dbmanager.InsertApprovalItems(dbh, this, slist);
                        break;
                    case TASKTYPE_UPDATE_INFO:
                        PriceInfo pi = SearchEngineManager.ExtractPriceInfo(this);
                        dbmanager.InsertPriceInfo(ProductId, EngineId, pi);
                        break;
                }
            }
            catch
            {
                Console.WriteLine("Member {0} failed", Id);
                Status = Errors++ == Member.ERROR_LIMIT ? STATUS_FAILED : STATUS_NEW;
            }
            // update the member's status
            dbh.ExecuteStoreCommand("update WebTask set Status={0}, Errors={1} where Id={2}",
                        Status, Errors, Id);

            dbh.SaveChanges();
        }

    }
}
