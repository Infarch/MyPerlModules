using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.Linq;
using System.Text;
using System.Windows.Forms;
using System.IO;

namespace BakiMT
{
    public partial class mainForm : Form
    {
        private bool timeA = false;

        CategoryRoot root;

        private MemberQueue queue;

        private List<BackgroundWorker> workers;

        public mainForm()
        {
            InitializeComponent();
            InitAsync();
        }

        private void InitAsync()
        {
            queue = new MemberQueue();

            workers = new List<BackgroundWorker>();
            // start 5 workers
            for (int i = 1; i < 5; i++)
            {
                DownloadWorker w = new DownloadWorker("W" + i);
                w.ProgressChanged += new ProgressChangedEventHandler(Worker_ProgressChanged);
                workers.Add(w);
            }
        }

        void Worker_ProgressChanged(object sender, ProgressChangedEventArgs e)
        {
            Log(e.UserState);
        }

        private void StartParser()
        {
            Log("Started at " + DateTime.Now.ToShortTimeString());

            btnStart.Enabled = false;
            btnView.Enabled = false;
            btnExport.Enabled = false;

            foreach (DownloadWorker w in workers) w.RunWorkerAsync(queue);

            timeA = false;
            timer.Start();

        }

        private void PopulateQueue()
        {
            root = new CategoryRoot();
            root.Name = "BAKI.INFO";
            queue.Enqueue(root);
        }

        private void Log(Object obj)
        {
            lbLog.Items.Add(obj);
            lbLog.SelectedIndex = lbLog.Items.Count - 1;
            lbLog.SelectedIndex = -1;
        }

        private void mainForm_FormClosing(object sender, FormClosingEventArgs e)
        {
            StopParser();
        }

        private void StopParser()
        {
            foreach (DownloadWorker w in workers) w.CancelAsync();
            foreach (DownloadWorker w in workers)
            {
                while (w.IsBusy) Application.DoEvents();
                Log("Stopped worker " + w.Id);
            }

            timer.Stop();
            btnStart.Enabled = true;
            btnView.Enabled = true;
            btnExport.Enabled = true;

            Log("Finished at " + DateTime.Now.ToShortTimeString());
        }

        private void btnStart_Click(object sender, EventArgs e)
        {
            PopulateQueue();
            StartParser();
        }

        private void timer_Tick(object sender, EventArgs e)
        {
            if (queue.Count == 0)
            {
                if (!timeA)
                {
                    timeA = true;
                }
                else
                {
                    StopParser();
                }
            }
            else
            {
                timeA = false;
            }
        }

        private void btnView_Click(object sender, EventArgs e)
        {
            if (root != null)
            {
                ViewForm frm = new ViewForm(root);
                frm.ShowDialog();
            }
            else Log("No data");
        }

        private void btnExport_Click(object sender, EventArgs e)
        {
            SaveFileDialog saveFileDialog1 = new SaveFileDialog();
            saveFileDialog1.Filter = "Comma separated values|*.csv";
            saveFileDialog1.Title = "Save data";
            saveFileDialog1.ShowDialog();
            if (saveFileDialog1.FileName != "")
            {
                Stream s = File.Open(saveFileDialog1.FileName, FileMode.Create, FileAccess.Write);
                Exporter.WriteToStream(s, root);
                s.Close();
                Log("Exported");

            }
        }
    }
}
