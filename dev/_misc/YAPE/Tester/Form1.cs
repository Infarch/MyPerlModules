using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.Linq;
using System.Text;
using System.Windows.Forms;
using System.Threading;
using System.Net;

using YAPE;

namespace Tester
{
    public partial class Form1 : Form
    {
        Engine engine;

        public Form1()
        {
            InitializeComponent();
            engine = new Engine();
            engine.OnFinish += new EventHandler(EngineSuccess);
            engine.OnCancel += new EventHandler(EngineCancelled);
            engine.OnError += new EventHandler(EngineFailed);
        }

        void EngineSuccess(object sender, EventArgs e)
        {
            label1.Text = "Success";
        }
        void EngineCancelled(object sender, EventArgs e)
        {
            label1.Text = "Cancelled";
        }
        void EngineFailed(object sender, EventArgs e)
        {
            label1.Text = "Failed";
        }

        void TestAction(Object arg)
        {
            Console.WriteLine("Started {0}", arg);
            Thread.Sleep(100);
            //throw new Exception();
            //Console.WriteLine("Finished {0}", arg);
        }

        void MethodA()
        {
            ArgProvider provider = new ArgProvider();
            engine.DoWorkAsync(TestAction, provider);
        }
        void MethodB()
        {
            ActionProvider provide = new ActionProvider();
            engine.DoWorkAsync(provide);
        }

        WebClient client;
        //ManualResetEvent mre;

        private void button1_Click(object sender, EventArgs e)
        {
            //MethodB();
            //button1.Enabled = false;

            //mre = new ManualResetEvent(false);

            client = new WebClient();
            
            client.DownloadDataCompleted+=new DownloadDataCompletedEventHandler((xxsender, xxe)=>{
                //mre.Set();
                Console.WriteLine("Encoding: {0}", client.Encoding);
            });

            client.DownloadDataAsync(new Uri("http://free-lance.ru/"));

            //mre.WaitOne();

            

        }

        private void button2_Click(object sender, EventArgs e)
        {
            engine.CancelAsync();
        }
    }
}
