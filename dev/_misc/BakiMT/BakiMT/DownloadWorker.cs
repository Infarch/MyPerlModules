using System;
using System.ComponentModel;
using System.Net;
using System.Text;
using System.Threading;

namespace BakiMT
{
    class DownloadWorker : BackgroundWorker
    {
        private String id;

        public String Id
        {
            get { return id; }
            set { id = value; }
        }

        public DownloadWorker(String id)
            : base()
        {
            Id = id;
            WorkerReportsProgress = true;
            WorkerSupportsCancellation = true;

            DoWork += new DoWorkEventHandler(DownloadWorker_DoWork);
        }

        void SendProgress(String s)
        {
            this.ReportProgress(0, Id + " : " + s);
        }

        void DownloadWorker_DoWork(object sender, DoWorkEventArgs e)
        {
            DownloadWorker worker = (DownloadWorker)sender;
            MemberQueue queue = (MemberQueue)e.Argument;

            WebClient client = new WebClient();
            client.Encoding = Encoding.UTF8;

            while (!worker.CancellationPending)
            {
                AbstractMember m = null;
                try
                {
                    if (queue.TryDequeue(out m))
                    {
                        MemberList ml = m.Process(client);
                        if (ml != null)
                        {
                            // enqueue new members
                            foreach(AbstractMember m1 in ml)
                                queue.Enqueue(m1);
                        }
                        SendProgress(m.GetTag());
                    }
                    else
                    {
                        // wait
                        Thread.Sleep(100);
                    }

                }
                catch (Exception ex)
                {
                    // report error
                    SendProgress(ex.Message);
                    // return the member to queue
                    queue.Enqueue(m);
                }
            }
            e.Cancel = true;
        }


    }
}
