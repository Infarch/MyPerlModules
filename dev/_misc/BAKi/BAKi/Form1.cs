using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.Linq;
using System.Text;
using System.Windows.Forms;
using System.Xml.Serialization;
using System.IO;


namespace BAKi
{
    public partial class Form1 : Form
    {

        private static String settingsXML = "isoft.parser.baki.xml";

        private String startUri = "http://baki.info/";

        private Category root;

        private Member currentMember;

        private bool isBusy = false;
        private bool hasOldData = false;
        private bool hasUnfinishedData = false;

        public bool HasUnfinishedData
        {
            get { return hasUnfinishedData; }
            set { hasUnfinishedData = value; }
        }

        public bool HasOldData
        {
            get { return hasOldData; }
            set { hasOldData = value; }
        }

        public bool IsBusy
        {
            get { return isBusy; }
            set { 
                isBusy = value;
                mData.Enabled = !value;
                statusLabel.Text = value ? "Please wait while the site is being parsed" : "Ready";
                mParserContinue.Enabled = !value && HasUnfinishedData;
                mParserNew.Enabled = !value;
                mParserStop.Enabled = value;
            }
        }


        public Form1()
        {
            InitializeComponent();

            // look for the old data in temp direcotry

            Object oldData = DeserializeData();
            if (oldData != null)
            {
                root = (Category)oldData;
                HasOldData = root.Children.Count > 0;
                currentMember = root.getNextUnprocessed();
                hasUnfinishedData = currentMember != null;
            }
            else
            {
                NewSession();
            }

            IsBusy = false;
        }

        private void NewSession()
        {
            root = new Category("root", startUri, true);
            currentMember = root;
            HasOldData = false;
            HasUnfinishedData = false;
        }

        private void Form1_Load(object sender, EventArgs e)
        {
            browser.DocumentCompleted += new WebBrowserDocumentCompletedEventHandler(browser_DocumentCompleted);
            browser.Navigating += new WebBrowserNavigatingEventHandler(browser_Navigating);
        }

        void browser_Navigating(object sender, WebBrowserNavigatingEventArgs e)
        {
            String host = e.Url.Host;
            if (host == "www.facebook.com" || host == "plusone.google.com")
            {
                e.Cancel = true;
            }
        }


        private void ProcessMember()
        {
            if (currentMember != null)
            {
                currentMember.Process(browser.Document);
                currentMember = root.getNextUnprocessed();
                if (currentMember != null)
                {
                    HasUnfinishedData = true;
                    browser.Navigate(currentMember.Url);
                }
                else
                {
                    HasUnfinishedData = false;
                    IsBusy = false;
                }
            }
            else IsBusy = false;
        }

        void browser_DocumentCompleted(object sender, WebBrowserDocumentCompletedEventArgs e)
        {
            if (timer.Enabled)
            {
                timer.Stop();
            }
            timer.Start();
        }

        public void SerializeData()
        {
            XmlSerializer sr = new XmlSerializer(root.GetType());
            StreamWriter writer = new StreamWriter(DataFileName());
            sr.Serialize(writer, root);
            writer.Close();
        }

        public Object DeserializeData()
        {
            String filename = DataFileName();
            Object obj = null;
            try
            {
                if (File.Exists(filename))
                {
                    XmlSerializer sr = new XmlSerializer(typeof(Category));
                    FileStream stream = new FileStream(filename, FileMode.Open);
                    obj = sr.Deserialize(stream);
                    stream.Close();
                }

            }
            catch (Exception) { } 
            return obj;
        }

        private String DataFileName()
        {
            return Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData), settingsXML);
        }

        private void timer_Tick(object sender, EventArgs e)
        {
            timer.Stop();
            ProcessMember();
        }

        private void mDataOverview_Click(object sender, EventArgs e)
        {
            DataOverviewForm frm = new DataOverviewForm(root);
            frm.ShowDialog();
        }

        private void Form1_FormClosing(object sender, FormClosingEventArgs e)
        {
            try
            {
                SerializeData();
            }
            catch (Exception ex)
            {
                MessageBox.Show(ex.Message);
            }
            
        }

        private void mParserContinue_Click(object sender, EventArgs e)
        {
            StartParser();
        }

        private void StartParser()
        {
            IsBusy = true;
            browser.Navigate(currentMember.Url);
        }

        private void mParserNew_Click(object sender, EventArgs e)
        {
            if (HasUnfinishedData &&
                MessageBox.Show("All old data will be removed. This is irreversible! Continue anyway?", "Warning", MessageBoxButtons.YesNo) != DialogResult.Yes)
            {
                return;
            }
            NewSession();
            StartParser();

        }
    }
}
