using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.Linq;
using System.Text;
using System.Windows.Forms;
using System.IO;
using System.Net.NetworkInformation;
using FormHelper;

namespace FreeSpamerPro
{
    public partial class Form1 : Form
    {
        private enum ParseMode {Ready, TakePeople, OpenPostBox, SendMessage};
        ParseMode mode = ParseMode.Ready;
        bool paused;

        Random random = new Random();

        // milliseconds
        int parsingPause = 1;
        int messagePause = 1;

        private TickList tlist;

        ProjectList projects = new ProjectList();
        ProjectUserList users = new ProjectUserList();
        ProjectUser currentUser;
        Project activeProject;
        bool changed;
        
        // we cannot use tbAttachment for storing attachment name due to dual purpose of the control.
        // the string below contains the last selected value of attachment file.
        String attach;

        public Form1()
        {
            InitializeComponent();
        }

        /// <summary>
        /// The main point for initialization operations
        /// </summary>
        /// <param name="sender"></param>
        /// <param name="e"></param>
        private void Form1_Load(object sender, EventArgs e)
        {
            // setup intervals
            cbParseInterval.ValueMember = "Tag";
            for (int i = 1; i < 11; i++)
            {
                cbParseInterval.Items.Add(new Interval(i));
            }

            cbMessageInterval.ValueMember = "Tag";
            for (int i = 1; i < 60; i++)
            {
                cbMessageInterval.Items.Add(new Interval(i));
            }

            for (int i = 1; i < 11; i++)
            {
                cbMessageInterval.Items.Add(new Interval(i * 60));
            }
            
            
            
            // setup browser
            browser.DocumentCompleted += new WebBrowserDocumentCompletedEventHandler(browser_DocumentCompleted);
            browser.Navigated += new WebBrowserNavigatedEventHandler(browser_Navigated);
            browser.Navigate("http://free-lance.ru");

            // setup data bindings
            lbProjects.DataSource = projects;
            lbProjects.DisplayMember = "Title";
            projects.Populate(new SQLiteDatabase());

            lbProjectUsers.DataSource = users;
            lbProjectUsers.DisplayMember = "Info";

            // other
            cbParseInterval.SelectedIndex = 0;
            cbMessageInterval.SelectedIndex = 0;

        }

        void browser_Navigated(object sender, WebBrowserNavigatedEventArgs e)
        {
            //Console.WriteLine("Navigated to " + e.Url);

            // iframes mut die!!!
            if (e.Url.ToString().Contains("iframe") || e.Url.ToString().Contains("about:blank")) return;

            SelectBrowserHandler();

        }


        void browser_DocumentCompleted(object sender, WebBrowserDocumentCompletedEventArgs e)
        {
            // well, this handler does not work enough well on some pages
            // iframes mut die!!!
            //if (e.Url.ToString().Contains("iframe")) return;
            //SelectBrowserHandler();

        }


        /// <summary>
        /// Returns a project according to selection in list.
        /// If none, returns NULL
        /// </summary>
        /// <returns></returns>
        Project GetProject()
        {
            return (Project)lbProjects.SelectedValue;
        }

        /// <summary>
        /// Populates the project editor's fields using the active project as a data source.
        /// </summary>
        void ShowActiveProject()
        {
            if (activeProject == null)
            {
                // no project, clean up fields
                tbProjectTitle.Text = "";
                tbProjectMessage.Text = "";
                tbAttachment.Text = "";
                attach = "";
            }
            else
            {
                // populate fields
                tbProjectTitle.Text = activeProject.Title;
                tbProjectMessage.Text = activeProject.Message;
                if (activeProject.Attachment != null && File.Exists(activeProject.Attachment))
                {
                    tbAttachment.Text = activeProject.Attachment;
                    attach = activeProject.Attachment;
                }
                else
                {
                    tbAttachment.Text = "< Empty or not exists >";
                    attach = "";
                }
            }
            ShowProjectUsers();
            // change Enable status of controls
            foreach (Control c in gbProjectControls.Controls)
            {
                c.Enabled = activeProject != null;
            }
        }

        /// <summary>
        /// Loads a project into the editor
        /// </summary>
        /// <param name="sender"></param>
        /// <param name="e"></param>
        private void btnLoadProject_Click(object sender, EventArgs e)
        {
            if (!AllowUnloadProject())
            {
                return;
            }
            
            activeProject = GetProject();
            ShowActiveProject();
            changed = false;
        }

        /// <summary>
        /// Creates a new, empty project
        /// </summary>
        /// <param name="sender"></param>
        /// <param name="e"></param>
        private void btnNewProject_Click(object sender, EventArgs e)
        {
            if (!AllowUnloadProject())
            {
                return;
            }

            activeProject = new Project();
            activeProject.Title = "New project";
            activeProject.Message = "Type your text here";
            attach = "";
            ShowActiveProject();

        }

        /// <summary>
        /// Checks whether it is allowed to unload the active project.
        /// The matter is that there might be some changes in project
        /// data need to be saved before unload the project
        /// </summary>
        /// <returns></returns>
        bool AllowUnloadProject()
        {
            if (activeProject != null && changed)
            {
                DialogResult r = MessageBox.Show(
                    "Active project has been changed. Do you want to save data before exit?", 
                    "Warning", MessageBoxButtons.YesNoCancel);
                if (r == DialogResult.No)
                {
                    return true;
                }
                else if (r == DialogResult.Cancel)
                {
                    return false;
                }
                else
                {
                    SaveActiveProject();
                }

            }
            return true;
        }

        /// <summary>
        /// Stores the active project into database
        /// </summary>
        private void SaveActiveProject()
        {
            activeProject.Title = tbProjectTitle.Text;
            activeProject.Message = tbProjectMessage.Text;
            activeProject.Attachment = attach;
            if (activeProject.Store(new SQLiteDatabase()))
            {
                // new project
                projects.Add(activeProject);
            }
        }

        /// <summary>
        /// Marks the active project as Changed
        /// </summary>
        /// <param name="sender"></param>
        /// <param name="e"></param>
        void ProjectDataChanged(object sender, EventArgs e)
        {
            changed = true;
        }

        /// <summary>
        /// Attachment button handler
        /// </summary>
        /// <param name="sender"></param>
        /// <param name="e"></param>
        private void btnAttach_Click(object sender, EventArgs e)
        {
            if (openFileDialog.ShowDialog() == DialogResult.OK)
            {
                attach = openFileDialog.FileName;
                tbAttachment.Text = openFileDialog.FileName;
                changed = true;
            }
        }

        private void btnSaveProject_Click(object sender, EventArgs e)
        {
            SaveActiveProject();
            changed = false;
        }

        private void btnRemoveAttach_Click(object sender, EventArgs e)
        {
            attach = "";
            changed = true;
            tbAttachment.Text = "< Empty or not exists >";
        }

        private void button1_Click(object sender, EventArgs e)
        {
            ShowProjectUsers();
        }

        /// <summary>
        /// Display complete list of users belong to active project
        /// </summary>
        private void ShowProjectUsers()
        {
            users.Clear();
            if (activeProject != null)
            {
                users.Populate(new SQLiteDatabase(), activeProject);
            }
        }

        /// <summary>
        /// Returns true if it is allowed to switch tabs. 
        /// Otherwise: a message will be displayed; function returns false.
        /// </summary>
        /// <param name="newindex"></param>
        /// <returns></returns>
        bool AllowSwitchTab(TabPage page)
        {
            bool ok = true;

            if (page == tabProject)
            {
                // from parser to project editor
                if (mode != ParseMode.Ready)
                {
                    ok = false;
                    MessageBox.Show("Please wait while the site is being parsed");
                }
            }
            else
            {
                // form project editor to parser
                if (activeProject == null)
                {
                    ok = false;
                    MessageBox.Show("Please load a project first");
                }
                else if (changed)
                {
                    ok = false;
                    MessageBox.Show("You have to save changes first");
                }
            }

            return ok;
        }

        private void tabControl1_Selecting(object sender, TabControlCancelEventArgs e)
        {
            e.Cancel = !AllowSwitchTab(e.TabPage);
        }

        /// <summary>
        /// Delete the active project
        /// </summary>
        /// <param name="sender"></param>
        /// <param name="e"></param>
        private void btnDeleteProject_Click(object sender, EventArgs e)
        {
            if (MessageBox.Show("Do you want to delete the project?", "Warning", MessageBoxButtons.OKCancel)==DialogResult.OK)
            {
                if (activeProject.Id != 0)
                {
                    activeProject.Delete(new SQLiteDatabase());
                    projects.Remove(activeProject);
                }
                activeProject = null;
                ShowActiveProject();
            }
        }

        /// <summary>
        /// Init process of taking users
        /// </summary>
        /// <param name="sender"></param>
        /// <param name="e"></param>
        private void btnTakeUsers_Click(object sender, EventArgs e)
        {
            tlist = new TickList();
            stProgress.Style = ProgressBarStyle.Marquee;
            stProgress.Visible = true;
            mode = ParseMode.TakePeople;
            btnTakeUsers.Enabled = false;
            btnSendMessage.Enabled = false;
            btnPause.Enabled = true;
            btnStop.Enabled = true;
            parseTimer.Start();
            TakePeople();
        }


        private void Log(Object obj)
        {
            /*
            lbLog.Items.Add(obj);
            lbLog.SelectedIndex = lbLog.Items.Count - 1;
            lbLog.SelectedIndex = -1;
             */
        }

        /// <summary>
        /// Schedule pause
        /// </summary>
        /// <param name="sender"></param>
        /// <param name="e"></param>
        private void btnPause_Click(object sender, EventArgs e)
        {
            if (paused)
            {
                btnPause.Text = "Pause";
                paused = false;
                parseTimer.Start();
            }
            else
            {
                parseTimer.Stop();
                btnPause.Text = "Resume";
                stText.Text = "Paused";
                paused = true;
            }
        }

        /// <summary>
        /// Change interval between parser's requests
        /// </summary>
        /// <param name="sender"></param>
        /// <param name="e"></param>
        private void cbParseInterval_SelectedIndexChanged(object sender, EventArgs e)
        {
            try 
            {
                parsingPause = ((Interval)cbParseInterval.SelectedItem).Seconds;
            }
            catch{}
        }

        /// <summary>
        /// Change interval between parser's requests
        /// </summary>
        /// <param name="sender"></param>
        /// <param name="e"></param>
        private void cbMessageInterval_SelectedIndexChanged(object sender, EventArgs e)
        {
            try
            {
                messagePause = ((Interval)cbMessageInterval.SelectedItem).Seconds;
            }
            catch { }
        }


        private void btnSendMessage_Click(object sender, EventArgs e)
        {
            tlist = new TickList();

            stProgress.Minimum = 0;
            stProgress.Maximum = users.Count(x => x.Notified == false);
            stProgress.Style = ProgressBarStyle.Continuous;
            stProgress.Visible = true;

            btnTakeUsers.Enabled = false;
            btnSendMessage.Enabled = false;
            btnPause.Enabled = true;
            btnStop.Enabled = true;
            parseTimer.Start();
            OpenPostBox();
        }

        /// <summary>
        /// Loads a project by double click action
        /// </summary>
        /// <param name="sender"></param>
        /// <param name="e"></param>
        private void lbProjects_MouseDoubleClick(object sender, MouseEventArgs e)
        {
            int index = lbProjects.IndexFromPoint(e.Location);
            Log("Index: " + index);
            if (index != System.Windows.Forms.ListBox.NoMatches)
            {
                if (!AllowUnloadProject())
                {
                    return;
                }

                activeProject = GetProject();
                ShowActiveProject();
                changed = false;
            }
        }

        private void parseTimer_Tick(object sender, EventArgs e)
        {
            ProcessTimer();
        }

        private void btnStop_Click(object sender, EventArgs e)
        {
            parseTimer.Stop();
            ResetParser();
        }

 
    }
}
