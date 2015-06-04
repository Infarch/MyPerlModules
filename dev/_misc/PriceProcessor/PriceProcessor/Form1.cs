using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.Linq;
using System.Text;
using System.Windows.Forms;
using System.IO;

using MyController = PriceProcessor.Controller.Controller;
using ControllerActionEventArgs = PriceProcessor.Controller.ControllerActionEventArgs;

namespace PriceProcessor
{
    public partial class MainForm : Form
    {

        MyController controller;
        UserAction doTasks;
        //bool Cancel;

        public MainForm()
        {
            InitializeComponent();
        }

        private string SelectDatabaseFile()
        {
            if (dlgOpenDatabase.ShowDialog() == DialogResult.OK)
            {
                return dlgOpenDatabase.FileName;
            }
            else return null;
        }

        void SetConrolsEnabled(bool state)
        {
            foreach (Control c in pnActions.Controls)
            {
                if (c is UserAction)
                {
                    if (!(c as UserAction).IsSpecial) c.Enabled = state;
                }
                else
                {
                    c.Enabled = state;
                }
            }

            progress.Visible = !state;
        }

        void DisableForm()
        {
            SetConrolsEnabled(false);
            doTasks.Enabled = false;
        }
        void EnableForm()
        {
            //if (!Cancel) SetConrolsEnabled(true);
            SetConrolsEnabled(true);
        }


        private void MainForm_Load(object sender, EventArgs e)
        {
            InitControls();

            string dbname = null;
            if (String.IsNullOrEmpty(Properties.Settings.Default.DataBaseFile) || !File.Exists(Properties.Settings.Default.DataBaseFile))
            {
                dbname = SelectDatabaseFile();
            }
            else
            {
                dbname = Properties.Settings.Default.DataBaseFile;
            }
            if (dbname != null)
            {
                Properties.Settings.Default.DataBaseFile = dbname;
                Properties.Settings.Default.Save();

                // create controller
                controller = MyController.GetController(dbname);
                
                // bind event handlers
                controller.OnInitComplete += new MyController.ControllerActionComplete(controller_OnInitComplete);
                controller.OnProcessTasksComplete += new MyController.ControllerActionComplete(controller_OnProcessTasksComplete);
                controller.OnLoadProductsComplete += new MyController.ControllerActionComplete(controller_OnLoadProductsComplete);
                controller.OnSearchProductsComplete += new MyController.ControllerActionComplete(controller_OnSearchProductsComplete);
                controller.OnExportApprovalListComplete += new MyController.ControllerActionComplete(controller_OnExportApprovalListComplete);
                controller.OnImportApprovalListComplete += new MyController.ControllerActionComplete(controller_OnImportApprovalListComplete);
                controller.OnUpdatePriceComplete += new MyController.ControllerActionComplete(controller_OnUpdatePriceComplete);
                // initialize
                controller.InitAsync();
            }
            else
            {
                MessageBox.Show("Cannot open database file", "Error");
                // close form
                Close();
            }

        }

        void controller_OnUpdatePriceComplete(object sender, ControllerActionEventArgs e)
        {
            if (e.Success)
            {
                if (!String.IsNullOrEmpty(e.Message)) MessageBox.Show(e.Message, "Notification");
            }
            else
            {
                MessageBox.Show("Error happened during updating prices. Details:\n" + e.Message, "Error");
            }
            EnableForm();
        }
        void controller_OnImportApprovalListComplete(object sender, ControllerActionEventArgs e)
        {
            if (e.Success)
            {
                if (!String.IsNullOrEmpty(e.Message)) MessageBox.Show(e.Message, "Notification");
            }
            else
            {
                MessageBox.Show("Error happened during importing approval list. Details:\n" + e.Message, "Error");
            }
            EnableForm();
        }
        void controller_OnExportApprovalListComplete(object sender, ControllerActionEventArgs e)
        {
            if (e.Success)
            {
                if (!String.IsNullOrEmpty(e.Message)) MessageBox.Show(e.Message, "Notification");
            }
            else
            {
                MessageBox.Show("Error happened during exporting approval list. Details:\n" + e.Message, "Error");
            }
            EnableForm();
        }
        void controller_OnSearchProductsComplete(object sender, ControllerActionEventArgs e)
        {
            if (e.Success)
            {
                if (!String.IsNullOrEmpty(e.Message)) MessageBox.Show(e.Message, "Notification");
            }
            else
            {
                MessageBox.Show("Error happened during searching products. Details:\n" + e.Message, "Error");
            }
            EnableForm();

        }
        void controller_OnLoadProductsComplete(object sender, ControllerActionEventArgs e)
        {
            if (e.Success)
            {
                if(!String.IsNullOrEmpty(e.Message)) MessageBox.Show(e.Message, "Notification");
            }
            else
            {
                MessageBox.Show("Error happened during loading products. Details:\n" + e.Message, "Error");
            }
            EnableForm();
        }
        void controller_OnProcessTasksComplete(object sender, ControllerActionEventArgs e)
        {
            if (e.Success)
            {
                if (!String.IsNullOrEmpty(e.Message)) MessageBox.Show(e.Message, "Notification");
                EnableForm();
            }
            else
            {
                MessageBox.Show("Error happened during processing of tasks. Please re-open application and try again. Details:\n" + e.Message, "Error");
            }
        }
        void controller_OnInitComplete(object sender, ControllerActionEventArgs e)
        {
            if (e.Success)
            {
                if (e.Summary.PendingTasksCount > 0)
                {
                    Console.WriteLine("There are {0} new tasks", e.Summary.PendingTasksCount);
                    doTasks.Enabled = true;
                }
                else
                {
                    EnableForm();
                }
            }
            else
            {
                MessageBox.Show("Could not start the business logic implementor: " + e.Message);
                Close();
            }

        }

        private void InitControls()
        {

            doTasks = new UserAction("Run pending tasks", false, DoTasks);
            doTasks.IsSpecial = true;
            pnActions.Controls.Add(doTasks);

            pnActions.Controls.Add(new UserAction("Load new products from CSV file...", false, LoadProductsCSV));
            pnActions.Controls.Add(new UserAction("Search products", false, SearchProducts));
            pnActions.Controls.Add(new UserAction("Export approval list...", false, ExportApprovalList));
            pnActions.Controls.Add(new UserAction("Import approval list...", false, ImportApprovalList));
            pnActions.Controls.Add(new UserAction("Update products prices", false, UpdatePrices));
        }

        void UpdatePrices()
        {
            if (ApproveLongTimeAction())
            {
                DisableForm();
                controller.UpdatePricesAsync();
            }
        }
        void ExportApprovalList()
        {
            if (dlgSaveCSV.ShowDialog() == DialogResult.OK)
            {
                DisableForm();
                controller.ExportApprovalListAsync(dlgSaveCSV.FileName);
            }
        }
        void SearchProducts()
        {
            if (ApproveLongTimeAction())
            {
                DisableForm();
                controller.SearchProductsAsync();
            }
        }

        bool ApproveLongTimeAction()
        {
            return MessageBox.Show("Operation might take a long time. Continue?", "Confirm") == DialogResult.OK;
        }

        void LoadProductsCSV()
        {
            if (dlgOpenCSV.ShowDialog() == DialogResult.OK)
            {
                DisableForm();
                controller.LoadProductsAsync(dlgOpenCSV.FileName);
            }
        }

        void ImportApprovalList()
        {
            if (dlgOpenCSV.ShowDialog() == DialogResult.OK)
            {
                DisableForm();
                controller.ImportApprovalListAsync(dlgOpenCSV.FileName);
            }
        }

        void DoTasks()
        {
            if (ApproveLongTimeAction())
            {
                DisableForm();
                controller.ProcessPendingTasksAsync();
            }
        }

        private void MainForm_FormClosing(object sender, FormClosingEventArgs e)
        {
            if (controller.IsBusy && e.CloseReason==CloseReason.UserClosing)
            {
                if (MessageBox.Show("Do you want to cancel the current operation?", "Confirm", MessageBoxButtons.YesNo) != DialogResult.Yes)
                {
                    e.Cancel = true;
                    return;
                }
            }
            controller.CancelTasks();
            //Cancel = true;
        }

    }
}
