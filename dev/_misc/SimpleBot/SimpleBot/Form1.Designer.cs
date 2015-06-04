namespace SimpleBot
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
            this.pnTools = new System.Windows.Forms.Panel();
            this.lbLinks = new System.Windows.Forms.ListBox();
            this.pnBrowsers = new System.Windows.Forms.FlowLayoutPanel();
            this.btnLoad = new System.Windows.Forms.Button();
            this.dlgOpen = new System.Windows.Forms.OpenFileDialog();
            this.btnStart = new System.Windows.Forms.Button();
            this.timer = new System.Windows.Forms.Timer(this.components);
            this.pnTools.SuspendLayout();
            this.SuspendLayout();
            // 
            // pnTools
            // 
            this.pnTools.BorderStyle = System.Windows.Forms.BorderStyle.FixedSingle;
            this.pnTools.Controls.Add(this.btnStart);
            this.pnTools.Controls.Add(this.btnLoad);
            this.pnTools.Dock = System.Windows.Forms.DockStyle.Top;
            this.pnTools.Location = new System.Drawing.Point(0, 0);
            this.pnTools.Name = "pnTools";
            this.pnTools.Size = new System.Drawing.Size(984, 46);
            this.pnTools.TabIndex = 0;
            // 
            // lbLinks
            // 
            this.lbLinks.Dock = System.Windows.Forms.DockStyle.Left;
            this.lbLinks.FormattingEnabled = true;
            this.lbLinks.HorizontalScrollbar = true;
            this.lbLinks.Location = new System.Drawing.Point(0, 46);
            this.lbLinks.Name = "lbLinks";
            this.lbLinks.SelectionMode = System.Windows.Forms.SelectionMode.None;
            this.lbLinks.Size = new System.Drawing.Size(164, 472);
            this.lbLinks.TabIndex = 1;
            // 
            // pnBrowsers
            // 
            this.pnBrowsers.AutoScroll = true;
            this.pnBrowsers.BorderStyle = System.Windows.Forms.BorderStyle.FixedSingle;
            this.pnBrowsers.Dock = System.Windows.Forms.DockStyle.Fill;
            this.pnBrowsers.Location = new System.Drawing.Point(164, 46);
            this.pnBrowsers.Name = "pnBrowsers";
            this.pnBrowsers.Size = new System.Drawing.Size(820, 472);
            this.pnBrowsers.TabIndex = 2;
            // 
            // btnLoad
            // 
            this.btnLoad.Location = new System.Drawing.Point(11, 11);
            this.btnLoad.Name = "btnLoad";
            this.btnLoad.Size = new System.Drawing.Size(75, 23);
            this.btnLoad.TabIndex = 0;
            this.btnLoad.Text = "Load...";
            this.btnLoad.UseVisualStyleBackColor = true;
            this.btnLoad.Click += new System.EventHandler(this.btnLoad_Click);
            // 
            // dlgOpen
            // 
            this.dlgOpen.Filter = "Text files|*.txt|All files|*.*";
            this.dlgOpen.Title = "Open file";
            // 
            // btnStart
            // 
            this.btnStart.Location = new System.Drawing.Point(176, 11);
            this.btnStart.Name = "btnStart";
            this.btnStart.Size = new System.Drawing.Size(75, 23);
            this.btnStart.TabIndex = 1;
            this.btnStart.Text = "Start";
            this.btnStart.UseVisualStyleBackColor = true;
            this.btnStart.Click += new System.EventHandler(this.btnStart_Click);
            // 
            // timer
            // 
            this.timer.Tick += new System.EventHandler(this.timer_Tick);
            // 
            // Form1
            // 
            this.AutoScaleDimensions = new System.Drawing.SizeF(6F, 13F);
            this.AutoScaleMode = System.Windows.Forms.AutoScaleMode.Font;
            this.ClientSize = new System.Drawing.Size(984, 518);
            this.Controls.Add(this.pnBrowsers);
            this.Controls.Add(this.lbLinks);
            this.Controls.Add(this.pnTools);
            this.MinimumSize = new System.Drawing.Size(600, 500);
            this.Name = "Form1";
            this.Text = "SimpleBot";
            this.pnTools.ResumeLayout(false);
            this.ResumeLayout(false);

        }

        #endregion

        private System.Windows.Forms.Panel pnTools;
        private System.Windows.Forms.Button btnLoad;
        private System.Windows.Forms.ListBox lbLinks;
        private System.Windows.Forms.FlowLayoutPanel pnBrowsers;
        private System.Windows.Forms.OpenFileDialog dlgOpen;
        private System.Windows.Forms.Button btnStart;
        private System.Windows.Forms.Timer timer;
    }
}

