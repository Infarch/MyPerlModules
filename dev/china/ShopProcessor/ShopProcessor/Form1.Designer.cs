namespace ShopProcessor
{
    partial class MainForm
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
            this.menuStrip1 = new System.Windows.Forms.MenuStrip();
            this.projectMenu = new System.Windows.Forms.ToolStripMenuItem();
            this.projectOpenMenu = new System.Windows.Forms.ToolStripMenuItem();
            this.toolStripSeparator1 = new System.Windows.Forms.ToolStripSeparator();
            this.projectDeleteMenu = new System.Windows.Forms.ToolStripMenuItem();
            this.toolStripSeparator2 = new System.Windows.Forms.ToolStripSeparator();
            this.projectCreateMenu = new System.Windows.Forms.ToolStripMenuItem();
            this.productMenu = new System.Windows.Forms.ToolStripMenuItem();
            this.productRenameMenu = new System.Windows.Forms.ToolStripMenuItem();
            this.productAbsorbMenu = new System.Windows.Forms.ToolStripMenuItem();
            this.toolStripSeparator3 = new System.Windows.Forms.ToolStripSeparator();
            this.productDeleteMenu = new System.Windows.Forms.ToolStripMenuItem();
            this.exportMenu = new System.Windows.Forms.ToolStripMenuItem();
            this.doExportMenu = new System.Windows.Forms.ToolStripMenuItem();
            this.statusStrip = new System.Windows.Forms.StatusStrip();
            this.slAppMode = new System.Windows.Forms.ToolStripStatusLabel();
            this.slQueueState = new System.Windows.Forms.ToolStripStatusLabel();
            this.pnContent = new System.Windows.Forms.Panel();
            this.tabControl = new System.Windows.Forms.TabControl();
            this.tabBrowser = new System.Windows.Forms.TabPage();
            this.btnBack = new System.Windows.Forms.Button();
            this.browser = new System.Windows.Forms.WebBrowser();
            this.btnTake = new System.Windows.Forms.Button();
            this.btnNavigate = new System.Windows.Forms.Button();
            this.tbUrl = new System.Windows.Forms.TextBox();
            this.tabProducts = new System.Windows.Forms.TabPage();
            this.pnProperties = new System.Windows.Forms.Panel();
            this.viewPhotos = new System.Windows.Forms.ListView();
            this.lbProducts = new System.Windows.Forms.ListBox();
            this.downloadWorker = new System.ComponentModel.BackgroundWorker();
            this.projectEditMenu = new System.Windows.Forms.ToolStripMenuItem();
            this.menuStrip1.SuspendLayout();
            this.statusStrip.SuspendLayout();
            this.pnContent.SuspendLayout();
            this.tabControl.SuspendLayout();
            this.tabBrowser.SuspendLayout();
            this.tabProducts.SuspendLayout();
            this.pnProperties.SuspendLayout();
            this.SuspendLayout();
            // 
            // menuStrip1
            // 
            this.menuStrip1.Items.AddRange(new System.Windows.Forms.ToolStripItem[] {
            this.projectMenu,
            this.productMenu,
            this.exportMenu});
            this.menuStrip1.Location = new System.Drawing.Point(0, 0);
            this.menuStrip1.Name = "menuStrip1";
            this.menuStrip1.Size = new System.Drawing.Size(771, 24);
            this.menuStrip1.TabIndex = 0;
            this.menuStrip1.Text = "menuStrip1";
            // 
            // projectMenu
            // 
            this.projectMenu.DropDownItems.AddRange(new System.Windows.Forms.ToolStripItem[] {
            this.projectOpenMenu,
            this.toolStripSeparator1,
            this.projectEditMenu,
            this.projectDeleteMenu,
            this.toolStripSeparator2,
            this.projectCreateMenu});
            this.projectMenu.Name = "projectMenu";
            this.projectMenu.Size = new System.Drawing.Size(56, 20);
            this.projectMenu.Text = "&Project";
            // 
            // projectOpenMenu
            // 
            this.projectOpenMenu.Name = "projectOpenMenu";
            this.projectOpenMenu.Size = new System.Drawing.Size(152, 22);
            this.projectOpenMenu.Text = "Open";
            this.projectOpenMenu.DropDownItemClicked += new System.Windows.Forms.ToolStripItemClickedEventHandler(this.projectOpenMenu_DropDownItemClicked);
            // 
            // toolStripSeparator1
            // 
            this.toolStripSeparator1.Name = "toolStripSeparator1";
            this.toolStripSeparator1.Size = new System.Drawing.Size(149, 6);
            // 
            // projectDeleteMenu
            // 
            this.projectDeleteMenu.Enabled = false;
            this.projectDeleteMenu.Name = "projectDeleteMenu";
            this.projectDeleteMenu.Size = new System.Drawing.Size(152, 22);
            this.projectDeleteMenu.Text = "Delete";
            this.projectDeleteMenu.Click += new System.EventHandler(this.projectDeleteMenu_Click);
            // 
            // toolStripSeparator2
            // 
            this.toolStripSeparator2.Name = "toolStripSeparator2";
            this.toolStripSeparator2.Size = new System.Drawing.Size(149, 6);
            // 
            // projectCreateMenu
            // 
            this.projectCreateMenu.Name = "projectCreateMenu";
            this.projectCreateMenu.Size = new System.Drawing.Size(152, 22);
            this.projectCreateMenu.Text = "Create...";
            this.projectCreateMenu.Click += new System.EventHandler(this.projectCreateMenu_Click);
            // 
            // productMenu
            // 
            this.productMenu.DropDownItems.AddRange(new System.Windows.Forms.ToolStripItem[] {
            this.productRenameMenu,
            this.productAbsorbMenu,
            this.toolStripSeparator3,
            this.productDeleteMenu});
            this.productMenu.Enabled = false;
            this.productMenu.Name = "productMenu";
            this.productMenu.Size = new System.Drawing.Size(61, 20);
            this.productMenu.Text = "P&roduct";
            // 
            // productRenameMenu
            // 
            this.productRenameMenu.Name = "productRenameMenu";
            this.productRenameMenu.Size = new System.Drawing.Size(126, 22);
            this.productRenameMenu.Text = "Rename...";
            this.productRenameMenu.Click += new System.EventHandler(this.productRenameMenu_Click);
            // 
            // productAbsorbMenu
            // 
            this.productAbsorbMenu.Name = "productAbsorbMenu";
            this.productAbsorbMenu.Size = new System.Drawing.Size(126, 22);
            this.productAbsorbMenu.Text = "Absorb...";
            this.productAbsorbMenu.Click += new System.EventHandler(this.productAbsorbMenu_Click);
            // 
            // toolStripSeparator3
            // 
            this.toolStripSeparator3.Name = "toolStripSeparator3";
            this.toolStripSeparator3.Size = new System.Drawing.Size(123, 6);
            // 
            // productDeleteMenu
            // 
            this.productDeleteMenu.Name = "productDeleteMenu";
            this.productDeleteMenu.Size = new System.Drawing.Size(126, 22);
            this.productDeleteMenu.Text = "Delete";
            this.productDeleteMenu.Click += new System.EventHandler(this.productDeleteMenu_Click);
            // 
            // exportMenu
            // 
            this.exportMenu.DropDownItems.AddRange(new System.Windows.Forms.ToolStripItem[] {
            this.doExportMenu});
            this.exportMenu.Enabled = false;
            this.exportMenu.Name = "exportMenu";
            this.exportMenu.Size = new System.Drawing.Size(52, 20);
            this.exportMenu.Text = "&Export";
            // 
            // doExportMenu
            // 
            this.doExportMenu.Name = "doExportMenu";
            this.doExportMenu.Size = new System.Drawing.Size(116, 22);
            this.doExportMenu.Text = "Export...";
            this.doExportMenu.Click += new System.EventHandler(this.doExportMenu_Click);
            // 
            // statusStrip
            // 
            this.statusStrip.Items.AddRange(new System.Windows.Forms.ToolStripItem[] {
            this.slAppMode,
            this.slQueueState});
            this.statusStrip.Location = new System.Drawing.Point(0, 562);
            this.statusStrip.Name = "statusStrip";
            this.statusStrip.Size = new System.Drawing.Size(771, 24);
            this.statusStrip.TabIndex = 1;
            this.statusStrip.Text = "statusStrip1";
            // 
            // slAppMode
            // 
            this.slAppMode.BorderSides = System.Windows.Forms.ToolStripStatusLabelBorderSides.Right;
            this.slAppMode.Name = "slAppMode";
            this.slAppMode.Size = new System.Drawing.Size(43, 19);
            this.slAppMode.Text = "Ready";
            // 
            // slQueueState
            // 
            this.slQueueState.BorderStyle = System.Windows.Forms.Border3DStyle.Raised;
            this.slQueueState.Name = "slQueueState";
            this.slQueueState.Size = new System.Drawing.Size(105, 19);
            this.slQueueState.Text = "Photos in queue: 0";
            // 
            // pnContent
            // 
            this.pnContent.Controls.Add(this.tabControl);
            this.pnContent.Dock = System.Windows.Forms.DockStyle.Fill;
            this.pnContent.Location = new System.Drawing.Point(0, 24);
            this.pnContent.Name = "pnContent";
            this.pnContent.Size = new System.Drawing.Size(771, 538);
            this.pnContent.TabIndex = 2;
            // 
            // tabControl
            // 
            this.tabControl.Controls.Add(this.tabBrowser);
            this.tabControl.Controls.Add(this.tabProducts);
            this.tabControl.Dock = System.Windows.Forms.DockStyle.Fill;
            this.tabControl.Location = new System.Drawing.Point(0, 0);
            this.tabControl.Name = "tabControl";
            this.tabControl.SelectedIndex = 0;
            this.tabControl.Size = new System.Drawing.Size(771, 538);
            this.tabControl.TabIndex = 0;
            this.tabControl.SelectedIndexChanged += new System.EventHandler(this.tabControl_SelectedIndexChanged);
            // 
            // tabBrowser
            // 
            this.tabBrowser.BackColor = System.Drawing.Color.LightGray;
            this.tabBrowser.Controls.Add(this.btnBack);
            this.tabBrowser.Controls.Add(this.browser);
            this.tabBrowser.Controls.Add(this.btnTake);
            this.tabBrowser.Controls.Add(this.btnNavigate);
            this.tabBrowser.Controls.Add(this.tbUrl);
            this.tabBrowser.Location = new System.Drawing.Point(4, 22);
            this.tabBrowser.Name = "tabBrowser";
            this.tabBrowser.Padding = new System.Windows.Forms.Padding(3);
            this.tabBrowser.Size = new System.Drawing.Size(763, 512);
            this.tabBrowser.TabIndex = 0;
            this.tabBrowser.Text = "Browser";
            // 
            // btnBack
            // 
            this.btnBack.Location = new System.Drawing.Point(498, 6);
            this.btnBack.Name = "btnBack";
            this.btnBack.Size = new System.Drawing.Size(75, 23);
            this.btnBack.TabIndex = 4;
            this.btnBack.Text = "Back";
            this.btnBack.UseVisualStyleBackColor = true;
            this.btnBack.Click += new System.EventHandler(this.btnBack_Click);
            // 
            // browser
            // 
            this.browser.Anchor = ((System.Windows.Forms.AnchorStyles)((((System.Windows.Forms.AnchorStyles.Top | System.Windows.Forms.AnchorStyles.Bottom)
                        | System.Windows.Forms.AnchorStyles.Left)
                        | System.Windows.Forms.AnchorStyles.Right)));
            this.browser.Location = new System.Drawing.Point(8, 35);
            this.browser.MinimumSize = new System.Drawing.Size(20, 20);
            this.browser.Name = "browser";
            this.browser.Size = new System.Drawing.Size(747, 471);
            this.browser.TabIndex = 3;
            // 
            // btnTake
            // 
            this.btnTake.Anchor = ((System.Windows.Forms.AnchorStyles)((System.Windows.Forms.AnchorStyles.Top | System.Windows.Forms.AnchorStyles.Right)));
            this.btnTake.Enabled = false;
            this.btnTake.Location = new System.Drawing.Point(663, 6);
            this.btnTake.Name = "btnTake";
            this.btnTake.Size = new System.Drawing.Size(92, 23);
            this.btnTake.TabIndex = 2;
            this.btnTake.Text = "Take products";
            this.btnTake.UseVisualStyleBackColor = true;
            this.btnTake.Click += new System.EventHandler(this.btnTake_Click);
            // 
            // btnNavigate
            // 
            this.btnNavigate.Location = new System.Drawing.Point(417, 6);
            this.btnNavigate.Name = "btnNavigate";
            this.btnNavigate.Size = new System.Drawing.Size(75, 23);
            this.btnNavigate.TabIndex = 1;
            this.btnNavigate.Text = "Navigate";
            this.btnNavigate.UseVisualStyleBackColor = true;
            this.btnNavigate.Click += new System.EventHandler(this.btnNavigate_Click);
            // 
            // tbUrl
            // 
            this.tbUrl.Location = new System.Drawing.Point(8, 6);
            this.tbUrl.Name = "tbUrl";
            this.tbUrl.Size = new System.Drawing.Size(403, 20);
            this.tbUrl.TabIndex = 0;
            this.tbUrl.Text = "http://v.yupoo.com/photos/lilycute2013/albums/";
            // 
            // tabProducts
            // 
            this.tabProducts.BackColor = System.Drawing.Color.LightGray;
            this.tabProducts.Controls.Add(this.pnProperties);
            this.tabProducts.Controls.Add(this.lbProducts);
            this.tabProducts.Location = new System.Drawing.Point(4, 22);
            this.tabProducts.Name = "tabProducts";
            this.tabProducts.Padding = new System.Windows.Forms.Padding(3);
            this.tabProducts.Size = new System.Drawing.Size(763, 512);
            this.tabProducts.TabIndex = 1;
            this.tabProducts.Text = "Products";
            // 
            // pnProperties
            // 
            this.pnProperties.Anchor = ((System.Windows.Forms.AnchorStyles)((((System.Windows.Forms.AnchorStyles.Top | System.Windows.Forms.AnchorStyles.Bottom)
                        | System.Windows.Forms.AnchorStyles.Left)
                        | System.Windows.Forms.AnchorStyles.Right)));
            this.pnProperties.AutoScroll = true;
            this.pnProperties.Controls.Add(this.viewPhotos);
            this.pnProperties.Location = new System.Drawing.Point(281, 6);
            this.pnProperties.Name = "pnProperties";
            this.pnProperties.Size = new System.Drawing.Size(476, 500);
            this.pnProperties.TabIndex = 1;
            // 
            // viewPhotos
            // 
            this.viewPhotos.Anchor = ((System.Windows.Forms.AnchorStyles)(((System.Windows.Forms.AnchorStyles.Top | System.Windows.Forms.AnchorStyles.Left)
                        | System.Windows.Forms.AnchorStyles.Right)));
            this.viewPhotos.CheckBoxes = true;
            this.viewPhotos.Location = new System.Drawing.Point(0, 0);
            this.viewPhotos.Name = "viewPhotos";
            this.viewPhotos.Size = new System.Drawing.Size(476, 153);
            this.viewPhotos.TabIndex = 0;
            this.viewPhotos.UseCompatibleStateImageBehavior = false;
            this.viewPhotos.ItemChecked += new System.Windows.Forms.ItemCheckedEventHandler(this.viewPhotos_ItemChecked);
            // 
            // lbProducts
            // 
            this.lbProducts.Anchor = ((System.Windows.Forms.AnchorStyles)(((System.Windows.Forms.AnchorStyles.Top | System.Windows.Forms.AnchorStyles.Bottom)
                        | System.Windows.Forms.AnchorStyles.Left)));
            this.lbProducts.FormattingEnabled = true;
            this.lbProducts.HorizontalScrollbar = true;
            this.lbProducts.Location = new System.Drawing.Point(3, 6);
            this.lbProducts.Name = "lbProducts";
            this.lbProducts.Size = new System.Drawing.Size(272, 498);
            this.lbProducts.TabIndex = 0;
            this.lbProducts.SelectedIndexChanged += new System.EventHandler(this.lbProducts_SelectedIndexChanged);
            // 
            // downloadWorker
            // 
            this.downloadWorker.WorkerReportsProgress = true;
            this.downloadWorker.WorkerSupportsCancellation = true;
            this.downloadWorker.DoWork += new System.ComponentModel.DoWorkEventHandler(this.downloadWorker_DoWork);
            this.downloadWorker.ProgressChanged += new System.ComponentModel.ProgressChangedEventHandler(this.downloadWorker_ProgressChanged);
            // 
            // projectEditMenu
            // 
            this.projectEditMenu.Enabled = false;
            this.projectEditMenu.Name = "projectEditMenu";
            this.projectEditMenu.Size = new System.Drawing.Size(152, 22);
            this.projectEditMenu.Text = "Edit...";
            this.projectEditMenu.Click += new System.EventHandler(this.projectEditMenu_Click);
            // 
            // MainForm
            // 
            this.AutoScaleDimensions = new System.Drawing.SizeF(6F, 13F);
            this.AutoScaleMode = System.Windows.Forms.AutoScaleMode.Font;
            this.ClientSize = new System.Drawing.Size(771, 586);
            this.Controls.Add(this.pnContent);
            this.Controls.Add(this.statusStrip);
            this.Controls.Add(this.menuStrip1);
            this.MainMenuStrip = this.menuStrip1;
            this.MinimumSize = new System.Drawing.Size(787, 624);
            this.Name = "MainForm";
            this.Text = "Shop processor";
            this.FormClosing += new System.Windows.Forms.FormClosingEventHandler(this.MainForm_FormClosing);
            this.Load += new System.EventHandler(this.MainForm_Load);
            this.menuStrip1.ResumeLayout(false);
            this.menuStrip1.PerformLayout();
            this.statusStrip.ResumeLayout(false);
            this.statusStrip.PerformLayout();
            this.pnContent.ResumeLayout(false);
            this.tabControl.ResumeLayout(false);
            this.tabBrowser.ResumeLayout(false);
            this.tabBrowser.PerformLayout();
            this.tabProducts.ResumeLayout(false);
            this.pnProperties.ResumeLayout(false);
            this.ResumeLayout(false);
            this.PerformLayout();

        }

        #endregion

        private System.Windows.Forms.MenuStrip menuStrip1;
        private System.Windows.Forms.ToolStripMenuItem projectMenu;
        private System.Windows.Forms.ToolStripMenuItem projectOpenMenu;
        private System.Windows.Forms.ToolStripMenuItem projectCreateMenu;
        private System.Windows.Forms.ToolStripSeparator toolStripSeparator1;
        private System.Windows.Forms.ToolStripMenuItem projectDeleteMenu;
        private System.Windows.Forms.ToolStripSeparator toolStripSeparator2;
        private System.Windows.Forms.StatusStrip statusStrip;
        private System.Windows.Forms.ToolStripStatusLabel slAppMode;
        private System.Windows.Forms.Panel pnContent;
        private System.Windows.Forms.TabControl tabControl;
        private System.Windows.Forms.TabPage tabBrowser;
        private System.Windows.Forms.WebBrowser browser;
        private System.Windows.Forms.Button btnTake;
        private System.Windows.Forms.Button btnNavigate;
        private System.Windows.Forms.TextBox tbUrl;
        private System.Windows.Forms.TabPage tabProducts;
        private System.Windows.Forms.ToolStripStatusLabel slQueueState;
        private System.ComponentModel.BackgroundWorker downloadWorker;
        private System.Windows.Forms.ListBox lbProducts;
        private System.Windows.Forms.Button btnBack;
        private System.Windows.Forms.Panel pnProperties;
        private System.Windows.Forms.ListView viewPhotos;
        private System.Windows.Forms.ToolStripMenuItem productMenu;
        private System.Windows.Forms.ToolStripMenuItem productRenameMenu;
        private System.Windows.Forms.ToolStripSeparator toolStripSeparator3;
        private System.Windows.Forms.ToolStripMenuItem productDeleteMenu;
        private System.Windows.Forms.ToolStripMenuItem productAbsorbMenu;
        private System.Windows.Forms.ToolStripMenuItem exportMenu;
        private System.Windows.Forms.ToolStripMenuItem doExportMenu;
        private System.Windows.Forms.ToolStripMenuItem projectEditMenu;
    }
}

