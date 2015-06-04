namespace BAKi
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
            this.browser = new System.Windows.Forms.WebBrowser();
            this.timer = new System.Windows.Forms.Timer(this.components);
            this.statusStrip1 = new System.Windows.Forms.StatusStrip();
            this.statusLabel = new System.Windows.Forms.ToolStripStatusLabel();
            this.menuStrip1 = new System.Windows.Forms.MenuStrip();
            this.mParser = new System.Windows.Forms.ToolStripMenuItem();
            this.mData = new System.Windows.Forms.ToolStripMenuItem();
            this.mDataOverview = new System.Windows.Forms.ToolStripMenuItem();
            this.mParserContinue = new System.Windows.Forms.ToolStripMenuItem();
            this.mParserNew = new System.Windows.Forms.ToolStripMenuItem();
            this.mParserStop = new System.Windows.Forms.ToolStripMenuItem();
            this.mDataExport = new System.Windows.Forms.ToolStripMenuItem();
            this.statusStrip1.SuspendLayout();
            this.menuStrip1.SuspendLayout();
            this.SuspendLayout();
            // 
            // browser
            // 
            this.browser.Dock = System.Windows.Forms.DockStyle.Fill;
            this.browser.Location = new System.Drawing.Point(0, 0);
            this.browser.MinimumSize = new System.Drawing.Size(20, 20);
            this.browser.Name = "browser";
            this.browser.Size = new System.Drawing.Size(950, 663);
            this.browser.TabIndex = 1;
            // 
            // timer
            // 
            this.timer.Interval = 2000;
            this.timer.Tick += new System.EventHandler(this.timer_Tick);
            // 
            // statusStrip1
            // 
            this.statusStrip1.Items.AddRange(new System.Windows.Forms.ToolStripItem[] {
            this.statusLabel});
            this.statusStrip1.Location = new System.Drawing.Point(0, 641);
            this.statusStrip1.Name = "statusStrip1";
            this.statusStrip1.Size = new System.Drawing.Size(950, 22);
            this.statusStrip1.TabIndex = 2;
            this.statusStrip1.Text = "statusStrip1";
            // 
            // statusLabel
            // 
            this.statusLabel.Name = "statusLabel";
            this.statusLabel.Size = new System.Drawing.Size(39, 17);
            this.statusLabel.Text = "Ready";
            // 
            // menuStrip1
            // 
            this.menuStrip1.Items.AddRange(new System.Windows.Forms.ToolStripItem[] {
            this.mParser,
            this.mData});
            this.menuStrip1.Location = new System.Drawing.Point(0, 0);
            this.menuStrip1.Name = "menuStrip1";
            this.menuStrip1.Size = new System.Drawing.Size(950, 24);
            this.menuStrip1.TabIndex = 3;
            this.menuStrip1.Text = "menuStrip1";
            // 
            // mParser
            // 
            this.mParser.DropDownItems.AddRange(new System.Windows.Forms.ToolStripItem[] {
            this.mParserContinue,
            this.mParserNew,
            this.mParserStop});
            this.mParser.Name = "mParser";
            this.mParser.Size = new System.Drawing.Size(51, 20);
            this.mParser.Text = "Parser";
            // 
            // mData
            // 
            this.mData.DropDownItems.AddRange(new System.Windows.Forms.ToolStripItem[] {
            this.mDataOverview,
            this.mDataExport});
            this.mData.Name = "mData";
            this.mData.Size = new System.Drawing.Size(43, 20);
            this.mData.Text = "Data";
            // 
            // mDataOverview
            // 
            this.mDataOverview.Name = "mDataOverview";
            this.mDataOverview.Size = new System.Drawing.Size(152, 22);
            this.mDataOverview.Text = "Overview";
            this.mDataOverview.Click += new System.EventHandler(this.mDataOverview_Click);
            // 
            // mParserContinue
            // 
            this.mParserContinue.Name = "mParserContinue";
            this.mParserContinue.Size = new System.Drawing.Size(152, 22);
            this.mParserContinue.Text = "Continue";
            this.mParserContinue.Click += new System.EventHandler(this.mParserContinue_Click);
            // 
            // mParserNew
            // 
            this.mParserNew.Name = "mParserNew";
            this.mParserNew.Size = new System.Drawing.Size(152, 22);
            this.mParserNew.Text = "New";
            this.mParserNew.Click += new System.EventHandler(this.mParserNew_Click);
            // 
            // mParserStop
            // 
            this.mParserStop.Name = "mParserStop";
            this.mParserStop.Size = new System.Drawing.Size(152, 22);
            this.mParserStop.Text = "Stop";
            // 
            // mDataExport
            // 
            this.mDataExport.Name = "mDataExport";
            this.mDataExport.Size = new System.Drawing.Size(152, 22);
            this.mDataExport.Text = "Export";
            // 
            // Form1
            // 
            this.AutoScaleDimensions = new System.Drawing.SizeF(6F, 13F);
            this.AutoScaleMode = System.Windows.Forms.AutoScaleMode.Font;
            this.ClientSize = new System.Drawing.Size(950, 663);
            this.Controls.Add(this.statusStrip1);
            this.Controls.Add(this.menuStrip1);
            this.Controls.Add(this.browser);
            this.MainMenuStrip = this.menuStrip1;
            this.Name = "Form1";
            this.Text = "Form1";
            this.FormClosing += new System.Windows.Forms.FormClosingEventHandler(this.Form1_FormClosing);
            this.Load += new System.EventHandler(this.Form1_Load);
            this.statusStrip1.ResumeLayout(false);
            this.statusStrip1.PerformLayout();
            this.menuStrip1.ResumeLayout(false);
            this.menuStrip1.PerformLayout();
            this.ResumeLayout(false);
            this.PerformLayout();

        }

        #endregion

        private System.Windows.Forms.WebBrowser browser;
        private System.Windows.Forms.Timer timer;
        private System.Windows.Forms.StatusStrip statusStrip1;
        private System.Windows.Forms.ToolStripStatusLabel statusLabel;
        private System.Windows.Forms.MenuStrip menuStrip1;
        private System.Windows.Forms.ToolStripMenuItem mParser;
        private System.Windows.Forms.ToolStripMenuItem mData;
        private System.Windows.Forms.ToolStripMenuItem mDataOverview;
        private System.Windows.Forms.ToolStripMenuItem mParserContinue;
        private System.Windows.Forms.ToolStripMenuItem mParserNew;
        private System.Windows.Forms.ToolStripMenuItem mParserStop;
        private System.Windows.Forms.ToolStripMenuItem mDataExport;
    }
}

