using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.Linq;
using System.Text;
using System.Text.RegularExpressions;
using System.Threading;
using System.Windows.Forms;
using ShopProcessor.CSV;
using System.IO;

namespace ShopProcessor.UI
{
    public partial class ExportForm : Form
    {
        private Project project;
        
        public ExportForm(Project project) : base()
        {
            InitializeComponent();
            this.project = project;
        }

        private void ExportForm_Load(object sender, EventArgs e)
        {
            checker.RunWorkerAsync();
        }

        private void checker_DoWork(object sender, DoWorkEventArgs e)
        {
            BackgroundWorker worker = sender as BackgroundWorker;
            while (!worker.CancellationPending)
            {
                bool has_pending = false;
                bool has_no_photo = false;

                foreach (Product prod in project.Products)
                {
                    bool has_photo = false;
                    foreach (Photo photo in prod.Photos)
                    {
                        if (!photo.IsDownloaded && photo.IsActive) has_pending = true;
                        if (photo.IsDownloaded && photo.IsActive) has_photo = true;
                    }
                    if (!has_photo) has_no_photo = true;
                }

                bool[] result = new bool[] { has_pending, has_no_photo };
                worker.ReportProgress(0, result);

                Thread.Sleep(500);
            }
        }

        private void checker_ProgressChanged(object sender, ProgressChangedEventArgs e)
        {
            bool[] result = e.UserState as bool[];
            StringBuilder sb = new StringBuilder("A virtual detective is monitoring your project right now.\nHe says:\n");

            if (!result[0] && !result[1])
            {
                sb.Append("\nAll right. You may start the export.");
                btnExport.Enabled = true;
                checker.CancelAsync();
            }
            else
            {
                if (result[0]) sb.AppendLine("\nSome pictures are not downloaded yet.");
                if (result[1]) sb.AppendLine("\nSome products have not any picture.");
            }

            lbStatus.Text = sb.ToString();
        }

        private void DoCancel()
        {
            exporter.CancelAsync();
            checker.CancelAsync();
        }

        private void btnCancel_Click(object sender, EventArgs e)
        {
            DoCancel();
            this.DialogResult = DialogResult.Cancel;
        }

        private void ExportForm_FormClosing(object sender, FormClosingEventArgs e)
        {
            checker.CancelAsync();
            exporter.CancelAsync();
        }

        private Boolean Confirm(String message)
        {
            return MessageBox.Show(message, "Confirm", MessageBoxButtons.YesNo) == DialogResult.Yes;
        }

        private void btnExport_Click(object sender, EventArgs e)
        {
            if (Confirm("Are you ready for export?"))
            {
                FileHelper.PrepareOutput();

                btnExport.Enabled = false;
                progress.Minimum = 0;
                progress.Maximum = project.Products.Count;
                progress.Value = 0;
                progress.Visible = true;
                exporter.RunWorkerAsync();

            }
        }

        private void exporter_DoWork(object sender, DoWorkEventArgs e)
        {
            BackgroundWorker worker = sender as BackgroundWorker;

            String pc_key = Field.Article;

            int progress = 0;
            int code = int.Parse(tbCodeStart.Text);
            String prefix = tbCodePrefix.Text;

            StringBuilder sb = new StringBuilder();
            CSVProcessor.MakeHeader(FieldList.GetFields(), sb);

            foreach (Product prod in project.Products)
            {
                if (worker.CancellationPending) break;

                String product_code = "";
                prod.Data.TryGetValue(pc_key, out product_code);
                if ((product_code == "") || (product_code == null))
                {
                    product_code = prefix + code++;
                    prod.SetData(pc_key, product_code);
                }

                String picname = "ispc_" + product_code;

                int i = 1;
                foreach (Photo photo in prod.Photos)
                {
                    Image img = Image.FromFile(FileHelper.PathToPhoto(project, photo));
                    if (worker.CancellationPending) break;

                    // small thumbnail
                    String n1 = picname + "_" + i + "_th.jpg";
                    ImageConvertor.MakeSmallThumbnail(img, FileHelper.PathToOutputPhoto(n1));
                    if (worker.CancellationPending) break;

                    // large thumbnail
                    String n2 = picname + "_" + i + ".jpg";
                    ImageConvertor.MakeLargeThumbnail(img, FileHelper.PathToOutputPhoto(n2));
                    if (worker.CancellationPending) break;

                    // save original image
                    String n3 = picname + "_" + i + "_enl.jpg";
                    img.Save(FileHelper.PathToOutputPhoto(n2));
                    if (worker.CancellationPending) break;

                    prod.SetData(Field.PhotoName(i), n2 + "," + n1 + "," + n3);

                    // photo limit
                    if (i++ == 15) break;
                }

                CSVProcessor.AddRow(FieldList.GetFields(), sb, prod.Data);
                worker.ReportProgress(++progress);
            }

            // make cp1251 string
            String output = sb.ToString();

            Encoding te = Encoding.GetEncoding("windows-1251");
            Encoding se = Encoding.Unicode;

            byte[] sourceBytes = se.GetBytes(output);
            byte[] destBytes = Encoding.Convert(se, te, sourceBytes);

            char[] destChars = new char[te.GetCharCount(destBytes, 0, destBytes.Length)];
            te.GetChars(destBytes, 0, destBytes.Length, destChars, 0);
            output = new String(destChars);

            // remove '?'
            output = Regex.Replace(output, "\\?", "");

            String outfile = FileHelper.OutputCSV();
            TextWriter tw = new StreamWriter(outfile, false, te);
            tw.Write(output);
            tw.Close();

        }

        private void exporter_ProgressChanged(object sender, ProgressChangedEventArgs e)
        {
            progress.Value = e.ProgressPercentage;
        }

        private void exporter_RunWorkerCompleted(object sender, RunWorkerCompletedEventArgs e)
        {
            btnExport.Enabled = true;
            progress.Visible = false;
        }

        private void tbCodePrefix_Validating(object sender, CancelEventArgs e)
        {
            TextBox box = sender as TextBox;
            if (box.Text == "")
            {
                e.Cancel = true;
                MessageBox.Show("This field must not be empty");
            }
        }

        private void tbCodeStart_Validating(object sender, CancelEventArgs e)
        {
            TextBox box = sender as TextBox;
            try
            {
                int number = int.Parse(box.Text);
            }
            catch (FormatException)
            {
                e.Cancel = true;
                MessageBox.Show("You need to enter an integer");
            }
        }

    }
}
