using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Forms;
using System.Threading;

using Google.GData.Client;
using Google.GData.Photos;
using Google.Picasa;

namespace Picassa
{
    public partial class MainForm : Form
    {

        private List<Product> Products = new List<Product>();

        private delegate void UpdateProgress(int val);
        private delegate void UpdateGrid();

        private void updateProgress(int val)
        {
            progress.Value = val;
        }

        private void updateGrid()
        {
            Products.RemoveAt(0);
            grid.Rows.RemoveAt(0);
        }

        public MainForm()
        {
            InitializeComponent();
        }


        private void MainForm_Load(object sender, EventArgs e)
        {
            grid.AutoSizeColumnsMode = DataGridViewAutoSizeColumnsMode.Fill;
            grid.AutoSizeRowsMode = DataGridViewAutoSizeRowsMode.AllCells;

            DataGridViewTextBoxColumn col0 = new DataGridViewTextBoxColumn();
            col0.HeaderText = "Product";
            col0.Name = "Product";

            DataGridViewTextBoxColumn col1 = new DataGridViewTextBoxColumn();
            col1.HeaderText = "Album";
            col1.Name = "Album";

            DataGridViewTextBoxColumn col2 = new DataGridViewTextBoxColumn();
            col2.HeaderText = "Photos";
            col2.Name = "Photos";

            grid.Columns.AddRange(col0, col1, col2);
        }

        private void btnAddProduct_Click(object sender, EventArgs e)
        {
            var af = new AddProductForm();
            if (af.ShowDialog() == DialogResult.OK)
            {
                Product prod=af.Product;

                DataGridViewCell cel0 = new DataGridViewTextBoxCell();
                cel0.Value = prod.Name;

                DataGridViewCell cel1 = new DataGridViewTextBoxCell();
                cel1.Value = prod.AlbumName;

                DataGridViewCell cel2 = new DataGridViewTextBoxCell();
                cel2.Value = prod.Photos.Count;

                DataGridViewRow row = new DataGridViewRow();
                row.Cells.AddRange(cel0, cel1, cel2);

                grid.Rows.Add(row);

                Products.Add(prod);

                btnStart.Enabled = true;
            }
        }

        private void btnStart_Click(object sender, EventArgs e)
        {
            tbLogin.Enabled = false;
            tbPassword.Enabled = false;
            btnAddProduct.Enabled = false;
            btnStart.Enabled = false;

            int total = 0;
            foreach (var prod in Products)
                total += prod.Photos.Count;
            progress.Minimum = 0;
            progress.Maximum = total;
            progress.Visible = true;

            worker.RunWorkerAsync();
        }

        private void worker_DoWorkAsync(object sender, DoWorkEventArgs e)
        {
            try
            {
                GoogleService service = new GoogleService(tbLogin.Text, tbPassword.Text);
                int total = 0;
                while (Products.Count > 0)
                {
                    SemaphoreSlim sem = new SemaphoreSlim(5);
                    Product prod = Products[0];
                    List<Task> tasklist = new List<Task>();
                    Album ga = service.GetAlbum(prod.AlbumName);
                    foreach (Photo photo in prod.Photos)
                    {
                        var t = Task.Factory.StartNew(() =>
                        {
                            if (worker.CancellationPending) return;
                            sem.Wait();
                            try
                            {
                                PhotoData data = Yuppo.GetPhotoData(photo);
                                service.AddPhoto(ga, photo, data);
                            }
                            catch (Exception)
                            {
                                sem.Release();
                                throw;
                            }
                            sem.Release();
                            Invoke(new UpdateProgress(updateProgress), Interlocked.Increment(ref total));
                        });
                        tasklist.Add(t);
                    }
                    Task.WaitAll(tasklist.ToArray());

                    if (worker.CancellationPending) return;
                    Invoke(new UpdateGrid(updateGrid));
                }
            }
            catch (AggregateException ae)
            {
                StringBuilder sb = new StringBuilder("Agregate exception:" + Environment.NewLine + Environment.NewLine);
                foreach (Exception ex in ae.Flatten().InnerExceptions)
                {
                    sb.AppendLine(ex.Message + Environment.NewLine + ex.StackTrace + Environment.NewLine);
                }
                ShowReport(sb.ToString());
            }
            catch (Exception ex)
            {
                ShowReport(ex.Message + Environment.NewLine + ex.StackTrace);
            }
        }

        private void worker_RunWorkerCompleted(object sender, RunWorkerCompletedEventArgs e)
        {
            tbLogin.Enabled = true;
            tbPassword.Enabled = true;
            btnAddProduct.Enabled = true;
            btnStart.Enabled = Products.Count > 0;
            progress.Visible = false;
        }

        private void ShowReport(String message)
        {
            using (Reporter rep = new Reporter(message)) rep.ShowDialog();
        }
    }
}