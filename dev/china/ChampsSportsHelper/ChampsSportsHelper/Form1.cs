using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Forms;
using System.IO;
using System.Collections.Concurrent;

namespace ChampsSportsHelper
{
    public partial class Form1 : Form, IProgress<int>
    {
        private bool Monitoring = false;
        private bool ClosingState = false;

        //private ConcurrentDictionary<int, ProductModel> dictModels = new ConcurrentDictionary<int, ProductModel>();

        ModelsCollection mc = new ModelsCollection(Constants.StopListFile);
        private bool Exporting = false;

        public Form1()
        {
            InitializeComponent();

            Console.WriteLine("Started at {0}", DateTime.Now);

            // start clipboard monitoring
            nextClipboardViewer = (IntPtr)SetClipboardViewer((int)this.Handle);

            // create a directory for images
            if (!Directory.Exists(Constants.DownloadsDir))
                Directory.CreateDirectory(Constants.DownloadsDir);

            // create a directory for exports
            if (!Directory.Exists(Constants.ExportsDir))
                Directory.CreateDirectory(Constants.ExportsDir);

            // populate price fields by default values
            tbPriceMultiplier.Text = String.Format("{0:F1}", 1.5F);
            tbPriceAdd.Text = String.Format("{0:F2}", 20.0F);



            // ** Testing zone!!! **
            //Product prod = new Product(240820, "17075005");
            //prod.Process();





            // start timer
            timerInfo.Start();
        }

        private void Form1_FormClosed(object sender, FormClosedEventArgs e)
        {
            // restore the clipboard chain
            ChangeClipboardChain(this.Handle, nextClipboardViewer);
        }

        private void btnStartStop_Click(object sender, EventArgs e)
        {
            Monitoring = !Monitoring;
            if (Monitoring)
            {
                ((Button)sender).Text = "Stop monitoring";
                btnExport.Enabled = false;
            }
            else
            {
                ((Button)sender).Text = "Start monitoring";
            }
        }

        private void UpdateInfo()
        {
            int total = mc.Count;
            int done = mc.CountProcessed;
            int failed = mc.CountFailed;
            lblPendingCount.Text = (total - done).ToString();
            lblProcessedModels.Text = done.ToString();
            lblFailedCount.Text = failed.ToString();
            btnExport.Enabled = !Monitoring && !Exporting  && total > 0 && total == done + failed;
        }

        private void timerInfo_Tick(object sender, EventArgs e)
        {
            if (!ClosingState) UpdateInfo();
        }

        private void Form1_FormClosing(object sender, FormClosingEventArgs e)
        {
            if (mc.Count > 0 && e.CloseReason == CloseReason.UserClosing)
            {
                if (MessageBox.Show(
                    "You have unexported models. They will be lost after closing. Close anyway?", 
                    "Warning", MessageBoxButtons.YesNo) != DialogResult.Yes)
                {
                    e.Cancel = true;
                    return;
                }
            }

            timerInfo.Stop();
            ClosingState = true;
        }

        private async void btnExport_Click(object sender, EventArgs e)
        {
            // validate and parse inputs
            string mainCategory = tbMainCategory.Text;

            // validate the additional categories as integers but leave these values as stings
            List<string> moreCategories = new List<string>();
            if (!String.IsNullOrEmpty(tbAdditionalCategories.Text))
            {
                string[] parts = tbAdditionalCategories.Text.Split(new char[] { ';', ',', ' ' });
                foreach (string part in parts)
                {
                    int cid = 0;
                    if (!int.TryParse(part, out cid))
                    {
                        MessageBox.Show("Additional categories are in wrong format", "Error");
                        return;
                    }
                    moreCategories.Add(part);
                }
            }

            float priceMultiple = 1F;
            if (!String.IsNullOrEmpty(tbPriceMultiplier.Text))
            {
                if (!float.TryParse(tbPriceMultiplier.Text, out priceMultiple))
                {
                    MessageBox.Show("Price multiplier is in wrong format", "Error");
                    return;
                }
            }

            float priceAdd = 0;
            if (!String.IsNullOrEmpty(tbPriceAdd.Text))
            {
                if (!float.TryParse(tbPriceAdd.Text, out priceAdd))
                {
                    MessageBox.Show("Price add value is in wrong format", "Error");
                    return;
                }
            }

            // start exporting products
            Exporting = true;
            btnStartStop.Enabled = false;
            btnExport.Enabled = false;
            progressExport.Visible = true;
            progressExport.Maximum = mc.Count;

            string path = await Exporter.ExportModelsAsync(mc, mainCategory, moreCategories, priceMultiple, priceAdd, this);
            MessageBox.Show("All products have been exported to " + path);

            mc.Clear();
            btnStartStop.Enabled = true;
            progressExport.Visible = false;

            Exporting = false;
        }


        public void Report(int value)
        {
            this.BeginInvoke((Action)(() =>
            {
                this.progressExport.Value = value;
            }));
        }
    }
}
