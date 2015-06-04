namespace FreeSpamerPro
{
    partial class Form1
    {
        /// <summary>
        /// Required designer variable.
        /// </summary>
        private System.ComponentModel.IContainer components = null;

        /// <summary>
        /// Clean up any resources being used.
        /// </summary>
        /// <param name="disposing">true if managed resources should be disposed; otherwise, false.</param>
        protected override void Dispose(bool disposing)
        {
            if (disposing && (components != null))
            {
                components.Dispose();
            }
            base.Dispose(disposing);
        }

        #region Windows Form Designer generated code

        /// <summary>
        /// Required method for Designer support - do not modify
        /// the contents of this method with the code editor.
        /// </summary>
        private void InitializeComponent()
        {
            this.components = new System.ComponentModel.Container();
            this.tabControl1 = new System.Windows.Forms.TabControl();
            this.tabProject = new System.Windows.Forms.TabPage();
            this.groupBox1 = new System.Windows.Forms.GroupBox();
            this.btnRefreshUsers = new System.Windows.Forms.Button();
            this.lbProjectUsers = new System.Windows.Forms.ListBox();
            this.gbProjectControls = new System.Windows.Forms.GroupBox();
            this.lbLog = new System.Windows.Forms.ListBox();
            this.btnDeleteProject = new System.Windows.Forms.Button();
            this.btnSaveProject = new System.Windows.Forms.Button();
            this.btnRemoveAttach = new System.Windows.Forms.Button();
            this.btnAttach = new System.Windows.Forms.Button();
            this.tbAttachment = new System.Windows.Forms.TextBox();
            this.label4 = new System.Windows.Forms.Label();
            this.tbProjectMessage = new System.Windows.Forms.TextBox();
            this.label3 = new System.Windows.Forms.Label();
            this.tbProjectTitle = new System.Windows.Forms.TextBox();
            this.label2 = new System.Windows.Forms.Label();
            this.btnNewProject = new System.Windows.Forms.Button();
            this.btnLoadProject = new System.Windows.Forms.Button();
            this.lbProjects = new System.Windows.Forms.ListBox();
            this.label1 = new System.Windows.Forms.Label();
            this.tabBrowser = new System.Windows.Forms.TabPage();
            this.browser = new System.Windows.Forms.WebBrowser();
            this.panel1 = new System.Windows.Forms.Panel();
            this.btnStop = new System.Windows.Forms.Button();
            this.label6 = new System.Windows.Forms.Label();
            this.cbMessageInterval = new System.Windows.Forms.ComboBox();
            this.cbParseInterval = new System.Windows.Forms.ComboBox();
            this.label5 = new System.Windows.Forms.Label();
            this.btnPause = new System.Windows.Forms.Button();
            this.btnSendMessage = new System.Windows.Forms.Button();
            this.btnTakeUsers = new System.Windows.Forms.Button();
            this.statusStrip1 = new System.Windows.Forms.StatusStrip();
            this.stText = new System.Windows.Forms.ToolStripStatusLabel();
            this.stProgress = new System.Windows.Forms.ToolStripProgressBar();
            this.openFileDialog = new System.Windows.Forms.OpenFileDialog();
            this.parseTimer = new System.Windows.Forms.Timer(this.components);
            this.stEstimate = new System.Windows.Forms.ToolStripStatusLabel();
            this.cbRandom = new System.Windows.Forms.CheckBox();
            this.tabControl1.SuspendLayout();
            this.tabProject.SuspendLayout();
            this.groupBox1.SuspendLayout();
            this.gbProjectControls.SuspendLayout();
            this.tabBrowser.SuspendLayout();
            this.panel1.SuspendLayout();
            this.statusStrip1.SuspendLayout();
            this.SuspendLayout();
            // 
            // tabControl1
            // 
            this.tabControl1.Controls.Add(this.tabProject);
            this.tabControl1.Controls.Add(this.tabBrowser);
            this.tabControl1.Dock = System.Windows.Forms.DockStyle.Fill;
            this.tabControl1.Location = new System.Drawing.Point(0, 0);
            this.tabControl1.Name = "tabControl1";
            this.tabControl1.SelectedIndex = 0;
            this.tabControl1.Size = new System.Drawing.Size(1070, 680);
            this.tabControl1.TabIndex = 0;
            this.tabControl1.Selecting += new System.Windows.Forms.TabControlCancelEventHandler(this.tabControl1_Selecting);
            // 
            // tabProject
            // 
            this.tabProject.BackColor = System.Drawing.SystemColors.Control;
            this.tabProject.Controls.Add(this.groupBox1);
            this.tabProject.Controls.Add(this.gbProjectControls);
            this.tabProject.Controls.Add(this.btnNewProject);
            this.tabProject.Controls.Add(this.btnLoadProject);
            this.tabProject.Controls.Add(this.lbProjects);
            this.tabProject.Controls.Add(this.label1);
            this.tabProject.Location = new System.Drawing.Point(4, 22);
            this.tabProject.Name = "tabProject";
            this.tabProject.Padding = new System.Windows.Forms.Padding(3);
            this.tabProject.Size = new System.Drawing.Size(1062, 654);
            this.tabProject.TabIndex = 0;
            this.tabProject.Text = "Project";
            // 
            // groupBox1
            // 
            this.groupBox1.Controls.Add(this.btnRefreshUsers);
            this.groupBox1.Controls.Add(this.lbProjectUsers);
            this.groupBox1.Location = new System.Drawing.Point(800, 29);
            this.groupBox1.Name = "groupBox1";
            this.groupBox1.Size = new System.Drawing.Size(254, 529);
            this.groupBox1.TabIndex = 5;
            this.groupBox1.TabStop = false;
            this.groupBox1.Text = "Project users:";
            // 
            // btnRefreshUsers
            // 
            this.btnRefreshUsers.Location = new System.Drawing.Point(173, 500);
            this.btnRefreshUsers.Name = "btnRefreshUsers";
            this.btnRefreshUsers.Size = new System.Drawing.Size(75, 23);
            this.btnRefreshUsers.TabIndex = 1;
            this.btnRefreshUsers.Text = "Refresh";
            this.btnRefreshUsers.UseVisualStyleBackColor = true;
            this.btnRefreshUsers.Click += new System.EventHandler(this.button1_Click);
            // 
            // lbProjectUsers
            // 
            this.lbProjectUsers.FormattingEnabled = true;
            this.lbProjectUsers.Location = new System.Drawing.Point(6, 19);
            this.lbProjectUsers.Name = "lbProjectUsers";
            this.lbProjectUsers.Size = new System.Drawing.Size(242, 472);
            this.lbProjectUsers.TabIndex = 0;
            // 
            // gbProjectControls
            // 
            this.gbProjectControls.Controls.Add(this.lbLog);
            this.gbProjectControls.Controls.Add(this.btnDeleteProject);
            this.gbProjectControls.Controls.Add(this.btnSaveProject);
            this.gbProjectControls.Controls.Add(this.btnRemoveAttach);
            this.gbProjectControls.Controls.Add(this.btnAttach);
            this.gbProjectControls.Controls.Add(this.tbAttachment);
            this.gbProjectControls.Controls.Add(this.label4);
            this.gbProjectControls.Controls.Add(this.tbProjectMessage);
            this.gbProjectControls.Controls.Add(this.label3);
            this.gbProjectControls.Controls.Add(this.tbProjectTitle);
            this.gbProjectControls.Controls.Add(this.label2);
            this.gbProjectControls.Location = new System.Drawing.Point(223, 29);
            this.gbProjectControls.Name = "gbProjectControls";
            this.gbProjectControls.Size = new System.Drawing.Size(571, 529);
            this.gbProjectControls.TabIndex = 4;
            this.gbProjectControls.TabStop = false;
            this.gbProjectControls.Text = "Project data:";
            // 
            // lbLog
            // 
            this.lbLog.FormattingEnabled = true;
            this.lbLog.Location = new System.Drawing.Point(145, 285);
            this.lbLog.Name = "lbLog";
            this.lbLog.Size = new System.Drawing.Size(304, 212);
            this.lbLog.TabIndex = 10;
            this.lbLog.Visible = false;
            // 
            // btnDeleteProject
            // 
            this.btnDeleteProject.Enabled = false;
            this.btnDeleteProject.Location = new System.Drawing.Point(485, 321);
            this.btnDeleteProject.Name = "btnDeleteProject";
            this.btnDeleteProject.Size = new System.Drawing.Size(75, 23);
            this.btnDeleteProject.TabIndex = 9;
            this.btnDeleteProject.Text = "Delete project";
            this.btnDeleteProject.UseVisualStyleBackColor = true;
            this.btnDeleteProject.Click += new System.EventHandler(this.btnDeleteProject_Click);
            // 
            // btnSaveProject
            // 
            this.btnSaveProject.Enabled = false;
            this.btnSaveProject.Location = new System.Drawing.Point(9, 321);
            this.btnSaveProject.Name = "btnSaveProject";
            this.btnSaveProject.Size = new System.Drawing.Size(75, 23);
            this.btnSaveProject.TabIndex = 8;
            this.btnSaveProject.Text = "Save project";
            this.btnSaveProject.UseVisualStyleBackColor = true;
            this.btnSaveProject.Click += new System.EventHandler(this.btnSaveProject_Click);
            // 
            // btnRemoveAttach
            // 
            this.btnRemoveAttach.Enabled = false;
            this.btnRemoveAttach.Location = new System.Drawing.Point(449, 210);
            this.btnRemoveAttach.Name = "btnRemoveAttach";
            this.btnRemoveAttach.Size = new System.Drawing.Size(75, 23);
            this.btnRemoveAttach.TabIndex = 7;
            this.btnRemoveAttach.Text = "Remove...";
            this.btnRemoveAttach.UseVisualStyleBackColor = true;
            this.btnRemoveAttach.Click += new System.EventHandler(this.btnRemoveAttach_Click);
            // 
            // btnAttach
            // 
            this.btnAttach.Enabled = false;
            this.btnAttach.Location = new System.Drawing.Point(351, 210);
            this.btnAttach.Name = "btnAttach";
            this.btnAttach.Size = new System.Drawing.Size(75, 23);
            this.btnAttach.TabIndex = 6;
            this.btnAttach.Text = "Select...";
            this.btnAttach.UseVisualStyleBackColor = true;
            this.btnAttach.Click += new System.EventHandler(this.btnAttach_Click);
            // 
            // tbAttachment
            // 
            this.tbAttachment.Font = new System.Drawing.Font("Microsoft Sans Serif", 8.25F, System.Drawing.FontStyle.Italic, System.Drawing.GraphicsUnit.Point, ((byte)(204)));
            this.tbAttachment.Location = new System.Drawing.Point(9, 212);
            this.tbAttachment.Name = "tbAttachment";
            this.tbAttachment.ReadOnly = true;
            this.tbAttachment.Size = new System.Drawing.Size(336, 20);
            this.tbAttachment.TabIndex = 5;
            // 
            // label4
            // 
            this.label4.AutoSize = true;
            this.label4.Location = new System.Drawing.Point(6, 196);
            this.label4.Name = "label4";
            this.label4.Size = new System.Drawing.Size(64, 13);
            this.label4.TabIndex = 4;
            this.label4.Text = "Attachment:";
            // 
            // tbProjectMessage
            // 
            this.tbProjectMessage.Enabled = false;
            this.tbProjectMessage.Location = new System.Drawing.Point(9, 71);
            this.tbProjectMessage.Multiline = true;
            this.tbProjectMessage.Name = "tbProjectMessage";
            this.tbProjectMessage.Size = new System.Drawing.Size(551, 108);
            this.tbProjectMessage.TabIndex = 3;
            this.tbProjectMessage.TextChanged += new System.EventHandler(this.ProjectDataChanged);
            // 
            // label3
            // 
            this.label3.AutoSize = true;
            this.label3.Location = new System.Drawing.Point(6, 55);
            this.label3.Name = "label3";
            this.label3.Size = new System.Drawing.Size(53, 13);
            this.label3.TabIndex = 2;
            this.label3.Text = "Message:";
            // 
            // tbProjectTitle
            // 
            this.tbProjectTitle.Enabled = false;
            this.tbProjectTitle.Location = new System.Drawing.Point(42, 23);
            this.tbProjectTitle.Name = "tbProjectTitle";
            this.tbProjectTitle.Size = new System.Drawing.Size(384, 20);
            this.tbProjectTitle.TabIndex = 1;
            this.tbProjectTitle.TextChanged += new System.EventHandler(this.ProjectDataChanged);
            // 
            // label2
            // 
            this.label2.AutoSize = true;
            this.label2.Location = new System.Drawing.Point(6, 26);
            this.label2.Name = "label2";
            this.label2.Size = new System.Drawing.Size(30, 13);
            this.label2.TabIndex = 0;
            this.label2.Text = "Title:";
            // 
            // btnNewProject
            // 
            this.btnNewProject.Location = new System.Drawing.Point(133, 535);
            this.btnNewProject.Name = "btnNewProject";
            this.btnNewProject.Size = new System.Drawing.Size(75, 23);
            this.btnNewProject.TabIndex = 3;
            this.btnNewProject.Text = "New";
            this.btnNewProject.UseVisualStyleBackColor = true;
            this.btnNewProject.Click += new System.EventHandler(this.btnNewProject_Click);
            // 
            // btnLoadProject
            // 
            this.btnLoadProject.Location = new System.Drawing.Point(11, 535);
            this.btnLoadProject.Name = "btnLoadProject";
            this.btnLoadProject.Size = new System.Drawing.Size(75, 23);
            this.btnLoadProject.TabIndex = 2;
            this.btnLoadProject.Text = "Load";
            this.btnLoadProject.UseVisualStyleBackColor = true;
            this.btnLoadProject.Click += new System.EventHandler(this.btnLoadProject_Click);
            // 
            // lbProjects
            // 
            this.lbProjects.FormattingEnabled = true;
            this.lbProjects.Location = new System.Drawing.Point(11, 29);
            this.lbProjects.Name = "lbProjects";
            this.lbProjects.Size = new System.Drawing.Size(197, 498);
            this.lbProjects.TabIndex = 1;
            this.lbProjects.MouseDoubleClick += new System.Windows.Forms.MouseEventHandler(this.lbProjects_MouseDoubleClick);
            // 
            // label1
            // 
            this.label1.AutoSize = true;
            this.label1.Location = new System.Drawing.Point(8, 13);
            this.label1.Name = "label1";
            this.label1.Size = new System.Drawing.Size(48, 13);
            this.label1.TabIndex = 0;
            this.label1.Text = "Projects:";
            // 
            // tabBrowser
            // 
            this.tabBrowser.BackColor = System.Drawing.SystemColors.Control;
            this.tabBrowser.Controls.Add(this.browser);
            this.tabBrowser.Controls.Add(this.panel1);
            this.tabBrowser.Location = new System.Drawing.Point(4, 22);
            this.tabBrowser.Name = "tabBrowser";
            this.tabBrowser.Padding = new System.Windows.Forms.Padding(3);
            this.tabBrowser.Size = new System.Drawing.Size(1062, 654);
            this.tabBrowser.TabIndex = 1;
            this.tabBrowser.Text = "Browser";
            // 
            // browser
            // 
            this.browser.Anchor = ((System.Windows.Forms.AnchorStyles)((((System.Windows.Forms.AnchorStyles.Top | System.Windows.Forms.AnchorStyles.Bottom)
                        | System.Windows.Forms.AnchorStyles.Left)
                        | System.Windows.Forms.AnchorStyles.Right)));
            this.browser.Location = new System.Drawing.Point(3, 47);
            this.browser.MinimumSize = new System.Drawing.Size(20, 20);
            this.browser.Name = "browser";
            this.browser.Size = new System.Drawing.Size(1051, 586);
            this.browser.TabIndex = 1;
            // 
            // panel1
            // 
            this.panel1.Anchor = ((System.Windows.Forms.AnchorStyles)(((System.Windows.Forms.AnchorStyles.Top | System.Windows.Forms.AnchorStyles.Left)
                        | System.Windows.Forms.AnchorStyles.Right)));
            this.panel1.BorderStyle = System.Windows.Forms.BorderStyle.FixedSingle;
            this.panel1.Controls.Add(this.cbRandom);
            this.panel1.Controls.Add(this.btnStop);
            this.panel1.Controls.Add(this.label6);
            this.panel1.Controls.Add(this.cbMessageInterval);
            this.panel1.Controls.Add(this.cbParseInterval);
            this.panel1.Controls.Add(this.label5);
            this.panel1.Controls.Add(this.btnPause);
            this.panel1.Controls.Add(this.btnSendMessage);
            this.panel1.Controls.Add(this.btnTakeUsers);
            this.panel1.Location = new System.Drawing.Point(3, 6);
            this.panel1.Name = "panel1";
            this.panel1.Size = new System.Drawing.Size(1051, 35);
            this.panel1.TabIndex = 0;
            // 
            // btnStop
            // 
            this.btnStop.Enabled = false;
            this.btnStop.Location = new System.Drawing.Point(971, 3);
            this.btnStop.Name = "btnStop";
            this.btnStop.Size = new System.Drawing.Size(75, 23);
            this.btnStop.TabIndex = 6;
            this.btnStop.Text = "Stop";
            this.btnStop.UseVisualStyleBackColor = true;
            this.btnStop.Click += new System.EventHandler(this.btnStop_Click);
            // 
            // label6
            // 
            this.label6.AutoSize = true;
            this.label6.Location = new System.Drawing.Point(511, 8);
            this.label6.Name = "label6";
            this.label6.Size = new System.Drawing.Size(72, 13);
            this.label6.TabIndex = 5;
            this.label6.Text = "Send interval:";
            // 
            // cbMessageInterval
            // 
            this.cbMessageInterval.FormattingEnabled = true;
            this.cbMessageInterval.Location = new System.Drawing.Point(589, 5);
            this.cbMessageInterval.Name = "cbMessageInterval";
            this.cbMessageInterval.Size = new System.Drawing.Size(121, 21);
            this.cbMessageInterval.TabIndex = 4;
            this.cbMessageInterval.SelectedIndexChanged += new System.EventHandler(this.cbMessageInterval_SelectedIndexChanged);
            // 
            // cbParseInterval
            // 
            this.cbParseInterval.FormattingEnabled = true;
            this.cbParseInterval.Location = new System.Drawing.Point(372, 5);
            this.cbParseInterval.Name = "cbParseInterval";
            this.cbParseInterval.Size = new System.Drawing.Size(121, 21);
            this.cbParseInterval.TabIndex = 4;
            this.cbParseInterval.SelectedIndexChanged += new System.EventHandler(this.cbParseInterval_SelectedIndexChanged);
            // 
            // label5
            // 
            this.label5.AutoSize = true;
            this.label5.Location = new System.Drawing.Point(292, 8);
            this.label5.Name = "label5";
            this.label5.Size = new System.Drawing.Size(74, 13);
            this.label5.TabIndex = 3;
            this.label5.Text = "Parse interval:";
            // 
            // btnPause
            // 
            this.btnPause.Enabled = false;
            this.btnPause.Location = new System.Drawing.Point(890, 3);
            this.btnPause.Name = "btnPause";
            this.btnPause.Size = new System.Drawing.Size(75, 23);
            this.btnPause.TabIndex = 2;
            this.btnPause.Text = "Pause";
            this.btnPause.UseVisualStyleBackColor = true;
            this.btnPause.Click += new System.EventHandler(this.btnPause_Click);
            // 
            // btnSendMessage
            // 
            this.btnSendMessage.Location = new System.Drawing.Point(85, 3);
            this.btnSendMessage.Name = "btnSendMessage";
            this.btnSendMessage.Size = new System.Drawing.Size(91, 23);
            this.btnSendMessage.TabIndex = 1;
            this.btnSendMessage.Text = "Send message";
            this.btnSendMessage.UseVisualStyleBackColor = true;
            this.btnSendMessage.Click += new System.EventHandler(this.btnSendMessage_Click);
            // 
            // btnTakeUsers
            // 
            this.btnTakeUsers.Location = new System.Drawing.Point(4, 3);
            this.btnTakeUsers.Name = "btnTakeUsers";
            this.btnTakeUsers.Size = new System.Drawing.Size(75, 23);
            this.btnTakeUsers.TabIndex = 0;
            this.btnTakeUsers.Text = "Take users";
            this.btnTakeUsers.UseVisualStyleBackColor = true;
            this.btnTakeUsers.Click += new System.EventHandler(this.btnTakeUsers_Click);
            // 
            // statusStrip1
            // 
            this.statusStrip1.Items.AddRange(new System.Windows.Forms.ToolStripItem[] {
            this.stText,
            this.stProgress,
            this.stEstimate});
            this.statusStrip1.Location = new System.Drawing.Point(0, 658);
            this.statusStrip1.Name = "statusStrip1";
            this.statusStrip1.Size = new System.Drawing.Size(1070, 22);
            this.statusStrip1.TabIndex = 1;
            this.statusStrip1.Text = "statusStrip1";
            // 
            // stText
            // 
            this.stText.AutoSize = false;
            this.stText.Name = "stText";
            this.stText.Size = new System.Drawing.Size(200, 17);
            this.stText.Text = "Ready";
            this.stText.TextAlign = System.Drawing.ContentAlignment.MiddleLeft;
            // 
            // stProgress
            // 
            this.stProgress.AutoSize = false;
            this.stProgress.Name = "stProgress";
            this.stProgress.Size = new System.Drawing.Size(200, 16);
            this.stProgress.Visible = false;
            // 
            // parseTimer
            // 
            this.parseTimer.Interval = 1000;
            this.parseTimer.Tick += new System.EventHandler(this.parseTimer_Tick);
            // 
            // stEstimate
            // 
            this.stEstimate.Name = "stEstimate";
            this.stEstimate.Size = new System.Drawing.Size(0, 17);
            // 
            // cbRandom
            // 
            this.cbRandom.AutoSize = true;
            this.cbRandom.Location = new System.Drawing.Point(716, 7);
            this.cbRandom.Name = "cbRandom";
            this.cbRandom.Size = new System.Drawing.Size(66, 17);
            this.cbRandom.TabIndex = 8;
            this.cbRandom.Text = "Random";
            this.cbRandom.UseVisualStyleBackColor = true;
            // 
            // Form1
            // 
            this.AutoScaleDimensions = new System.Drawing.SizeF(6F, 13F);
            this.AutoScaleMode = System.Windows.Forms.AutoScaleMode.Font;
            this.ClientSize = new System.Drawing.Size(1070, 680);
            this.Controls.Add(this.statusStrip1);
            this.Controls.Add(this.tabControl1);
            this.FormBorderStyle = System.Windows.Forms.FormBorderStyle.FixedSingle;
            this.MaximizeBox = false;
            this.Name = "Form1";
            this.Text = "Free Spamer Pro";
            this.Load += new System.EventHandler(this.Form1_Load);
            this.tabControl1.ResumeLayout(false);
            this.tabProject.ResumeLayout(false);
            this.tabProject.PerformLayout();
            this.groupBox1.ResumeLayout(false);
            this.gbProjectControls.ResumeLayout(false);
            this.gbProjectControls.PerformLayout();
            this.tabBrowser.ResumeLayout(false);
            this.panel1.ResumeLayout(false);
            this.panel1.PerformLayout();
            this.statusStrip1.ResumeLayout(false);
            this.statusStrip1.PerformLayout();
            this.ResumeLayout(false);
            this.PerformLayout();

        }

        #endregion

        private System.Windows.Forms.TabControl tabControl1;
        private System.Windows.Forms.TabPage tabProject;
        private System.Windows.Forms.TabPage tabBrowser;
        private System.Windows.Forms.ListBox lbProjects;
        private System.Windows.Forms.Label label1;
        private System.Windows.Forms.GroupBox gbProjectControls;
        private System.Windows.Forms.Button btnRemoveAttach;
        private System.Windows.Forms.Button btnAttach;
        private System.Windows.Forms.TextBox tbAttachment;
        private System.Windows.Forms.Label label4;
        private System.Windows.Forms.TextBox tbProjectMessage;
        private System.Windows.Forms.Label label3;
        private System.Windows.Forms.TextBox tbProjectTitle;
        private System.Windows.Forms.Label label2;
        private System.Windows.Forms.Button btnNewProject;
        private System.Windows.Forms.Button btnLoadProject;
        private System.Windows.Forms.Button btnSaveProject;
        private System.Windows.Forms.StatusStrip statusStrip1;
        private System.Windows.Forms.OpenFileDialog openFileDialog;
        private System.Windows.Forms.GroupBox groupBox1;
        private System.Windows.Forms.Button btnRefreshUsers;
        private System.Windows.Forms.ListBox lbProjectUsers;
        private System.Windows.Forms.Panel panel1;
        private System.Windows.Forms.WebBrowser browser;
        private System.Windows.Forms.Button btnDeleteProject;
        private System.Windows.Forms.Button btnSendMessage;
        private System.Windows.Forms.Button btnTakeUsers;
        private System.Windows.Forms.ListBox lbLog;
        private System.Windows.Forms.Button btnPause;
        private System.Windows.Forms.ComboBox cbParseInterval;
        private System.Windows.Forms.Label label5;
        private System.Windows.Forms.Label label6;
        private System.Windows.Forms.ComboBox cbMessageInterval;
        private System.Windows.Forms.Button btnStop;
        private System.Windows.Forms.ToolStripStatusLabel stText;
        private System.Windows.Forms.ToolStripProgressBar stProgress;
        private System.Windows.Forms.Timer parseTimer;
        private System.Windows.Forms.ToolStripStatusLabel stEstimate;
        private System.Windows.Forms.CheckBox cbRandom;
    }
}

