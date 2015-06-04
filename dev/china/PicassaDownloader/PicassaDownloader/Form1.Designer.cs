namespace PicassaDownloader
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
            System.ComponentModel.ComponentResourceManager resources = new System.ComponentModel.ComponentResourceManager(typeof(Form1));
            this.tbUrl = new System.Windows.Forms.TextBox();
            this.btnGo = new System.Windows.Forms.Button();
            this.statusStrip1 = new System.Windows.Forms.StatusStrip();
            this.slStatus = new System.Windows.Forms.ToolStripStatusLabel();
            this.spProgress = new System.Windows.Forms.ToolStripProgressBar();
            this.flowPanel = new System.Windows.Forms.FlowLayoutPanel();
            this.downloadWorker = new System.ComponentModel.BackgroundWorker();
            this.pnNavigation = new System.Windows.Forms.Panel();
            this.pnToolbar = new System.Windows.Forms.Panel();
            this.tbCode = new System.Windows.Forms.TextBox();
            this.tbStartNumber = new System.Windows.Forms.TextBox();
            this.btnExport = new System.Windows.Forms.Button();
            this.btnExclude = new System.Windows.Forms.Button();
            this.btnNewGroup = new System.Windows.Forms.Button();
            this.btnUngroup = new System.Windows.Forms.Button();
            this.exportWorker = new System.ComponentModel.BackgroundWorker();
            this.statusStrip1.SuspendLayout();
            this.pnNavigation.SuspendLayout();
            this.pnToolbar.SuspendLayout();
            this.SuspendLayout();
            // 
            // tbUrl
            // 
            this.tbUrl.Anchor = ((System.Windows.Forms.AnchorStyles)(((System.Windows.Forms.AnchorStyles.Top | System.Windows.Forms.AnchorStyles.Left)
                        | System.Windows.Forms.AnchorStyles.Right)));
            this.tbUrl.Location = new System.Drawing.Point(12, 12);
            this.tbUrl.Name = "tbUrl";
            this.tbUrl.Size = new System.Drawing.Size(509, 20);
            this.tbUrl.TabIndex = 0;
            this.tbUrl.Text = "https://picasaweb.google.com/fashionbagforyou3/BagNew";
            // 
            // btnGo
            // 
            this.btnGo.Anchor = ((System.Windows.Forms.AnchorStyles)((System.Windows.Forms.AnchorStyles.Top | System.Windows.Forms.AnchorStyles.Right)));
            this.btnGo.Location = new System.Drawing.Point(527, 12);
            this.btnGo.Name = "btnGo";
            this.btnGo.Size = new System.Drawing.Size(45, 20);
            this.btnGo.TabIndex = 1;
            this.btnGo.Text = "Go";
            this.btnGo.UseVisualStyleBackColor = true;
            this.btnGo.Click += new System.EventHandler(this.btnGo_Click);
            // 
            // statusStrip1
            // 
            this.statusStrip1.Items.AddRange(new System.Windows.Forms.ToolStripItem[] {
            this.slStatus,
            this.spProgress});
            this.statusStrip1.Location = new System.Drawing.Point(0, 390);
            this.statusStrip1.Name = "statusStrip1";
            this.statusStrip1.Size = new System.Drawing.Size(584, 22);
            this.statusStrip1.TabIndex = 2;
            this.statusStrip1.Text = "statusStrip1";
            // 
            // slStatus
            // 
            this.slStatus.Name = "slStatus";
            this.slStatus.Size = new System.Drawing.Size(0, 17);
            // 
            // spProgress
            // 
            this.spProgress.Name = "spProgress";
            this.spProgress.Size = new System.Drawing.Size(100, 16);
            this.spProgress.Step = 1;
            this.spProgress.Visible = false;
            // 
            // flowPanel
            // 
            this.flowPanel.Anchor = ((System.Windows.Forms.AnchorStyles)((((System.Windows.Forms.AnchorStyles.Top | System.Windows.Forms.AnchorStyles.Bottom)
                        | System.Windows.Forms.AnchorStyles.Left)
                        | System.Windows.Forms.AnchorStyles.Right)));
            this.flowPanel.AutoScroll = true;
            this.flowPanel.Location = new System.Drawing.Point(12, 69);
            this.flowPanel.Name = "flowPanel";
            this.flowPanel.Size = new System.Drawing.Size(560, 318);
            this.flowPanel.TabIndex = 3;
            // 
            // downloadWorker
            // 
            this.downloadWorker.WorkerReportsProgress = true;
            this.downloadWorker.WorkerSupportsCancellation = true;
            this.downloadWorker.DoWork += new System.ComponentModel.DoWorkEventHandler(this.downloadWorker_DoWork);
            this.downloadWorker.ProgressChanged += new System.ComponentModel.ProgressChangedEventHandler(this.downloadWorker_ProgressChanged);
            this.downloadWorker.RunWorkerCompleted += new System.ComponentModel.RunWorkerCompletedEventHandler(this.downloadWorker_RunWorkerCompleted);
            // 
            // pnNavigation
            // 
            this.pnNavigation.Controls.Add(this.tbUrl);
            this.pnNavigation.Controls.Add(this.btnGo);
            this.pnNavigation.Dock = System.Windows.Forms.DockStyle.Top;
            this.pnNavigation.Location = new System.Drawing.Point(0, 0);
            this.pnNavigation.Name = "pnNavigation";
            this.pnNavigation.Size = new System.Drawing.Size(584, 34);
            this.pnNavigation.TabIndex = 4;
            // 
            // pnToolbar
            // 
            this.pnToolbar.Anchor = ((System.Windows.Forms.AnchorStyles)(((System.Windows.Forms.AnchorStyles.Top | System.Windows.Forms.AnchorStyles.Left)
                        | System.Windows.Forms.AnchorStyles.Right)));
            this.pnToolbar.Controls.Add(this.tbCode);
            this.pnToolbar.Controls.Add(this.tbStartNumber);
            this.pnToolbar.Controls.Add(this.btnExport);
            this.pnToolbar.Controls.Add(this.btnExclude);
            this.pnToolbar.Controls.Add(this.btnNewGroup);
            this.pnToolbar.Controls.Add(this.btnUngroup);
            this.pnToolbar.Location = new System.Drawing.Point(12, 40);
            this.pnToolbar.Name = "pnToolbar";
            this.pnToolbar.Size = new System.Drawing.Size(560, 24);
            this.pnToolbar.TabIndex = 5;
            // 
            // tbCode
            // 
            this.tbCode.Anchor = System.Windows.Forms.AnchorStyles.Right;
            this.tbCode.Location = new System.Drawing.Point(344, 2);
            this.tbCode.Name = "tbCode";
            this.tbCode.Size = new System.Drawing.Size(75, 20);
            this.tbCode.TabIndex = 5;
            this.tbCode.Text = "X-";
            this.tbCode.Validating += new System.ComponentModel.CancelEventHandler(this.tbCode_Validating);
            // 
            // tbStartNumber
            // 
            this.tbStartNumber.Anchor = System.Windows.Forms.AnchorStyles.Right;
            this.tbStartNumber.Location = new System.Drawing.Point(425, 2);
            this.tbStartNumber.Name = "tbStartNumber";
            this.tbStartNumber.Size = new System.Drawing.Size(42, 20);
            this.tbStartNumber.TabIndex = 4;
            this.tbStartNumber.Text = "1";
            this.tbStartNumber.Validating += new System.ComponentModel.CancelEventHandler(this.tbStartNumber_Validating);
            // 
            // btnExport
            // 
            this.btnExport.Anchor = System.Windows.Forms.AnchorStyles.Right;
            this.btnExport.Location = new System.Drawing.Point(485, 0);
            this.btnExport.Name = "btnExport";
            this.btnExport.Size = new System.Drawing.Size(75, 23);
            this.btnExport.TabIndex = 3;
            this.btnExport.Text = "Do export";
            this.btnExport.UseVisualStyleBackColor = true;
            this.btnExport.Click += new System.EventHandler(this.btnExport_Click);
            // 
            // btnExclude
            // 
            this.btnExclude.Location = new System.Drawing.Point(165, 0);
            this.btnExclude.Name = "btnExclude";
            this.btnExclude.Size = new System.Drawing.Size(75, 23);
            this.btnExclude.TabIndex = 2;
            this.btnExclude.Text = "Exclude";
            this.btnExclude.UseVisualStyleBackColor = true;
            this.btnExclude.Click += new System.EventHandler(this.btnExclude_Click);
            // 
            // btnNewGroup
            // 
            this.btnNewGroup.Location = new System.Drawing.Point(84, 0);
            this.btnNewGroup.Name = "btnNewGroup";
            this.btnNewGroup.Size = new System.Drawing.Size(75, 23);
            this.btnNewGroup.TabIndex = 1;
            this.btnNewGroup.Text = "New group";
            this.btnNewGroup.UseVisualStyleBackColor = true;
            this.btnNewGroup.Click += new System.EventHandler(this.btnNewGroup_Click);
            // 
            // btnUngroup
            // 
            this.btnUngroup.Location = new System.Drawing.Point(0, 0);
            this.btnUngroup.Name = "btnUngroup";
            this.btnUngroup.Size = new System.Drawing.Size(75, 23);
            this.btnUngroup.TabIndex = 0;
            this.btnUngroup.Text = "No group";
            this.btnUngroup.UseVisualStyleBackColor = true;
            this.btnUngroup.Click += new System.EventHandler(this.btnUngroup_Click);
            // 
            // exportWorker
            // 
            this.exportWorker.WorkerReportsProgress = true;
            this.exportWorker.WorkerSupportsCancellation = true;
            this.exportWorker.DoWork += new System.ComponentModel.DoWorkEventHandler(this.exportWorker_DoWork);
            this.exportWorker.ProgressChanged += new System.ComponentModel.ProgressChangedEventHandler(this.exportWorker_ProgressChanged);
            this.exportWorker.RunWorkerCompleted += new System.ComponentModel.RunWorkerCompletedEventHandler(this.exportWorker_RunWorkerCompleted);
            // 
            // Form1
            // 
            this.AutoScaleDimensions = new System.Drawing.SizeF(6F, 13F);
            this.AutoScaleMode = System.Windows.Forms.AutoScaleMode.Font;
            this.ClientSize = new System.Drawing.Size(584, 412);
            this.Controls.Add(this.pnToolbar);
            this.Controls.Add(this.pnNavigation);
            this.Controls.Add(this.flowPanel);
            this.Controls.Add(this.statusStrip1);
            this.Icon = ((System.Drawing.Icon)(resources.GetObject("$this.Icon")));
            this.MinimumSize = new System.Drawing.Size(600, 450);
            this.Name = "Form1";
            this.Text = "Picassa downloader";
            this.FormClosing += new System.Windows.Forms.FormClosingEventHandler(this.Form1_FormClosing);
            this.Load += new System.EventHandler(this.Form1_Load);
            this.statusStrip1.ResumeLayout(false);
            this.statusStrip1.PerformLayout();
            this.pnNavigation.ResumeLayout(false);
            this.pnNavigation.PerformLayout();
            this.pnToolbar.ResumeLayout(false);
            this.pnToolbar.PerformLayout();
            this.ResumeLayout(false);
            this.PerformLayout();

        }

        #endregion

        private System.Windows.Forms.TextBox tbUrl;
        private System.Windows.Forms.Button btnGo;
        private System.Windows.Forms.StatusStrip statusStrip1;
        private System.Windows.Forms.ToolStripStatusLabel slStatus;
        private System.Windows.Forms.ToolStripProgressBar spProgress;
        private System.Windows.Forms.FlowLayoutPanel flowPanel;
        private System.ComponentModel.BackgroundWorker downloadWorker;
        private System.Windows.Forms.Panel pnNavigation;
        private System.Windows.Forms.Panel pnToolbar;
        private System.Windows.Forms.Button btnExclude;
        private System.Windows.Forms.Button btnNewGroup;
        private System.Windows.Forms.Button btnUngroup;
        private System.Windows.Forms.Button btnExport;
        private System.Windows.Forms.TextBox tbCode;
        private System.Windows.Forms.TextBox tbStartNumber;
        private System.ComponentModel.BackgroundWorker exportWorker;
    }
}

