using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

using System.Threading;
using System.Threading.Tasks;

namespace Parser.CommonClasses
{
    public class Parser
    {

        TaskScheduler scheduler;
        CancellationTokenSource tokenSource;
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



        public Parser()
        {
            try
            {
                scheduler = TaskScheduler.FromCurrentSynchronizationContext();
            }
            catch (InvalidOperationException)
            {
                scheduler = TaskScheduler.Default;
            }
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
        }


    }
}
