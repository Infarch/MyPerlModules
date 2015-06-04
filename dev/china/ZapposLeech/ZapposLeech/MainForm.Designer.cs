namespace ZapposLeech
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
            this.components = new System.ComponentModel.Container();
            this.label1 = new System.Windows.Forms.Label();
            this.tbUrl = new System.Windows.Forms.TextBox();
            this.label2 = new System.Windows.Forms.Label();
            this.tbFolder = new System.Windows.Forms.TextBox();
            this.btnSelectFolder = new System.Windows.Forms.Button();
            this.label3 = new System.Windows.Forms.Label();
            this.tbSkuPrefix = new System.Windows.Forms.TextBox();
            this.label4 = new System.Windows.Forms.Label();
            this.tbPricePercents = new System.Windows.Forms.TextBox();
            this.label5 = new System.Windows.Forms.Label();
            this.cbFonts = new System.Windows.Forms.ComboBox();
            this.label6 = new System.Windows.Forms.Label();
            this.cbBrandFontSize = new System.Windows.Forms.ComboBox();
            this.label7 = new System.Windows.Forms.Label();
            this.cbNameSize = new System.Windows.Forms.ComboBox();
            this.label8 = new System.Windows.Forms.Label();
            this.cbBottomSize = new System.Windows.Forms.ComboBox();
            this.dlgTargetFolder = new System.Windows.Forms.FolderBrowserDialog();
            this.btnRunTask = new System.Windows.Forms.Button();
            this.errorProvider = new System.Windows.Forms.ErrorProvider(this.components);
            this.worker = new System.ComponentModel.BackgroundWorker();
            this.progress = new System.Windows.Forms.ProgressBar();
            this.lblProgressMessage = new System.Windows.Forms.Label();
            this.photoLimit = new System.Windows.Forms.NumericUpDown();
            this.label9 = new System.Windows.Forms.Label();
            this.label10 = new System.Windows.Forms.Label();
            this.directoryLimit = new System.Windows.Forms.NumericUpDown();
            this.label11 = new System.Windows.Forms.Label();
            ((System.ComponentModel.ISupportInitialize)(this.errorProvider)).BeginInit();
            ((System.ComponentModel.ISupportInitialize)(this.photoLimit)).BeginInit();
            ((System.ComponentModel.ISupportInitialize)(this.directoryLimit)).BeginInit();
            this.SuspendLayout();
            // 
            // label1
            // 
            this.label1.AutoSize = true;
            this.label1.Location = new System.Drawing.Point(12, 9);
            this.label1.Name = "label1";
            this.label1.Size = new System.Drawing.Size(23, 13);
            this.label1.TabIndex = 0;
            this.label1.Text = "Url:";
            // 
            // tbUrl
            // 
            this.tbUrl.Location = new System.Drawing.Point(12, 25);
            this.tbUrl.Name = "tbUrl";
            this.tbUrl.Size = new System.Drawing.Size(418, 20);
            this.tbUrl.TabIndex = 1;
            // 
            // label2
            // 
            this.label2.AutoSize = true;
            this.label2.Location = new System.Drawing.Point(12, 59);
            this.label2.Name = "label2";
            this.label2.Size = new System.Drawing.Size(70, 13);
            this.label2.TabIndex = 2;
            this.label2.Text = "Target folder:";
            // 
            // tbFolder
            // 
            this.tbFolder.Location = new System.Drawing.Point(98, 77);
            this.tbFolder.Name = "tbFolder";
            this.tbFolder.ReadOnly = true;
            this.tbFolder.Size = new System.Drawing.Size(332, 20);
            this.tbFolder.TabIndex = 3;
            // 
            // btnSelectFolder
            // 
            this.btnSelectFolder.Location = new System.Drawing.Point(12, 75);
            this.btnSelectFolder.Name = "btnSelectFolder";
            this.btnSelectFolder.Size = new System.Drawing.Size(75, 23);
            this.btnSelectFolder.TabIndex = 4;
            this.btnSelectFolder.Text = "Select...";
            this.btnSelectFolder.UseVisualStyleBackColor = true;
            this.btnSelectFolder.Click += new System.EventHandler(this.btnSelectFolder_Click);
            // 
            // label3
            // 
            this.label3.AutoSize = true;
            this.label3.Location = new System.Drawing.Point(12, 111);
            this.label3.Name = "label3";
            this.label3.Size = new System.Drawing.Size(60, 13);
            this.label3.TabIndex = 5;
            this.label3.Text = "SKU prefix:";
            // 
            // tbSkuPrefix
            // 
            this.tbSkuPrefix.Location = new System.Drawing.Point(12, 127);
            this.tbSkuPrefix.Name = "tbSkuPrefix";
            this.tbSkuPrefix.Size = new System.Drawing.Size(121, 20);
            this.tbSkuPrefix.TabIndex = 6;
            // 
            // label4
            // 
            this.label4.AutoSize = true;
            this.label4.Location = new System.Drawing.Point(175, 111);
            this.label4.Name = "label4";
            this.label4.Size = new System.Drawing.Size(127, 13);
            this.label4.TabIndex = 7;
            this.label4.Text = "Increase price (percents):";
            // 
            // tbPricePercents
            // 
            this.tbPricePercents.Location = new System.Drawing.Point(178, 127);
            this.tbPricePercents.Name = "tbPricePercents";
            this.tbPricePercents.Size = new System.Drawing.Size(124, 20);
            this.tbPricePercents.TabIndex = 8;
            this.tbPricePercents.Text = "20";
            // 
            // label5
            // 
            this.label5.AutoSize = true;
            this.label5.Location = new System.Drawing.Point(12, 161);
            this.label5.Name = "label5";
            this.label5.Size = new System.Drawing.Size(60, 13);
            this.label5.TabIndex = 9;
            this.label5.Text = "Font family:";
            // 
            // cbFonts
            // 
            this.cbFonts.DropDownStyle = System.Windows.Forms.ComboBoxStyle.DropDownList;
            this.cbFonts.FormattingEnabled = true;
            this.cbFonts.Location = new System.Drawing.Point(12, 177);
            this.cbFonts.Name = "cbFonts";
            this.cbFonts.Size = new System.Drawing.Size(121, 21);
            this.cbFonts.TabIndex = 10;
            // 
            // label6
            // 
            this.label6.AutoSize = true;
            this.label6.Location = new System.Drawing.Point(175, 161);
            this.label6.Name = "label6";
            this.label6.Size = new System.Drawing.Size(59, 13);
            this.label6.TabIndex = 11;
            this.label6.Text = "Brand size:";
            // 
            // cbBrandFontSize
            // 
            this.cbBrandFontSize.DropDownStyle = System.Windows.Forms.ComboBoxStyle.DropDownList;
            this.cbBrandFontSize.FormattingEnabled = true;
            this.cbBrandFontSize.Location = new System.Drawing.Point(178, 177);
            this.cbBrandFontSize.Name = "cbBrandFontSize";
            this.cbBrandFontSize.Size = new System.Drawing.Size(80, 21);
            this.cbBrandFontSize.TabIndex = 12;
            // 
            // label7
            // 
            this.label7.AutoSize = true;
            this.label7.Location = new System.Drawing.Point(261, 161);
            this.label7.Name = "label7";
            this.label7.Size = new System.Drawing.Size(59, 13);
            this.label7.TabIndex = 13;
            this.label7.Text = "Name size:";
            // 
            // cbNameSize
            // 
            this.cbNameSize.DropDownStyle = System.Windows.Forms.ComboBoxStyle.DropDownList;
            this.cbNameSize.FormattingEnabled = true;
            this.cbNameSize.Location = new System.Drawing.Point(264, 177);
            this.cbNameSize.Name = "cbNameSize";
            this.cbNameSize.Size = new System.Drawing.Size(80, 21);
            this.cbNameSize.TabIndex = 14;
            // 
            // label8
            // 
            this.label8.AutoSize = true;
            this.label8.Location = new System.Drawing.Point(347, 161);
            this.label8.Name = "label8";
            this.label8.Size = new System.Drawing.Size(83, 13);
            this.label8.TabIndex = 15;
            this.label8.Text = "Bottom line size:";
            // 
            // cbBottomSize
            // 
            this.cbBottomSize.DropDownStyle = System.Windows.Forms.ComboBoxStyle.DropDownList;
            this.cbBottomSize.FormattingEnabled = true;
            this.cbBottomSize.Location = new System.Drawing.Point(350, 177);
            this.cbBottomSize.Name = "cbBottomSize";
            this.cbBottomSize.Size = new System.Drawing.Size(80, 21);
            this.cbBottomSize.TabIndex = 16;
            // 
            // dlgTargetFolder
            // 
            this.dlgTargetFolder.Description = "Select a folder for images";
            this.dlgTargetFolder.RootFolder = System.Environment.SpecialFolder.MyComputer;
            // 
            // btnRunTask
            // 
            this.btnRunTask.Anchor = ((System.Windows.Forms.AnchorStyles)((System.Windows.Forms.AnchorStyles.Bottom | System.Windows.Forms.AnchorStyles.Left)));
            this.btnRunTask.Location = new System.Drawing.Point(355, 289);
            this.btnRunTask.Name = "btnRunTask";
            this.btnRunTask.Size = new System.Drawing.Size(75, 23);
            this.btnRunTask.TabIndex = 17;
            this.btnRunTask.Text = "Run task";
            this.btnRunTask.UseVisualStyleBackColor = true;
            this.btnRunTask.Click += new System.EventHandler(this.btnRunTask_Click);
            // 
            // errorProvider
            // 
            this.errorProvider.ContainerControl = this;
            // 
            // worker
            // 
            this.worker.WorkerReportsProgress = true;
            this.worker.WorkerSupportsCancellation = true;
            this.worker.DoWork += new System.ComponentModel.DoWorkEventHandler(this.worker_DoWork);
            this.worker.ProgressChanged += new System.ComponentModel.ProgressChangedEventHandler(this.worker_ProgressChanged);
            this.worker.RunWorkerCompleted += new System.ComponentModel.RunWorkerCompletedEventHandler(this.worker_RunWorkerCompleted);
            // 
            // progress
            // 
            this.progress.Anchor = ((System.Windows.Forms.AnchorStyles)((System.Windows.Forms.AnchorStyles.Bottom | System.Windows.Forms.AnchorStyles.Left)));
            this.progress.Location = new System.Drawing.Point(12, 289);
            this.progress.Name = "progress";
            this.progress.Size = new System.Drawing.Size(246, 23);
            this.progress.Style = System.Windows.Forms.ProgressBarStyle.Continuous;
            this.progress.TabIndex = 18;
            this.progress.Visible = false;
            // 
            // lblProgressMessage
            // 
            this.lblProgressMessage.Anchor = ((System.Windows.Forms.AnchorStyles)((System.Windows.Forms.AnchorStyles.Bottom | System.Windows.Forms.AnchorStyles.Left)));
            this.lblProgressMessage.AutoSize = true;
            this.lblProgressMessage.Location = new System.Drawing.Point(12, 268);
            this.lblProgressMessage.Name = "lblProgressMessage";
            this.lblProgressMessage.Size = new System.Drawing.Size(0, 13);
            this.lblProgressMessage.TabIndex = 19;
            // 
            // photoLimit
            // 
            this.photoLimit.Location = new System.Drawing.Point(12, 226);
            this.photoLimit.Maximum = new decimal(new int[] {
            20,
            0,
            0,
            0});
            this.photoLimit.Minimum = new decimal(new int[] {
            1,
            0,
            0,
            0});
            this.photoLimit.Name = "photoLimit";
            this.photoLimit.Size = new System.Drawing.Size(75, 20);
            this.photoLimit.TabIndex = 20;
            this.photoLimit.Value = new decimal(new int[] {
            2,
            0,
            0,
            0});
            // 
            // label9
            // 
            this.label9.AutoSize = true;
            this.label9.Location = new System.Drawing.Point(12, 210);
            this.label9.Name = "label9";
            this.label9.Size = new System.Drawing.Size(63, 13);
            this.label9.TabIndex = 21;
            this.label9.Text = "Photos limit:";
            // 
            // label10
            // 
            this.label10.AutoSize = true;
            this.label10.Location = new System.Drawing.Point(175, 210);
            this.label10.Name = "label10";
            this.label10.Size = new System.Drawing.Size(120, 13);
            this.label10.TabIndex = 22;
            this.label10.Text = "Photos per folder, up to:";
            // 
            // directoryLimit
            // 
            this.directoryLimit.Increment = new decimal(new int[] {
            10,
            0,
            0,
            0});
            this.directoryLimit.Location = new System.Drawing.Point(178, 226);
            this.directoryLimit.Maximum = new decimal(new int[] {
            50000,
            0,
            0,
            0});
            this.directoryLimit.Name = "directoryLimit";
            this.directoryLimit.Size = new System.Drawing.Size(117, 20);
            this.directoryLimit.TabIndex = 23;
            this.directoryLimit.Value = new decimal(new int[] {
            20,
            0,
            0,
            0});
            // 
            // label11
            // 
            this.label11.AutoSize = true;
            this.label11.Location = new System.Drawing.Point(301, 228);
            this.label11.Name = "label11";
            this.label11.Size = new System.Drawing.Size(134, 13);
            this.label11.TabIndex = 24;
            this.label11.Text = "\"0\" means \"no separation\"";
            // 
            // MainForm
            // 
            this.AutoScaleDimensions = new System.Drawing.SizeF(6F, 13F);
            this.AutoScaleMode = System.Windows.Forms.AutoScaleMode.Font;
            this.ClientSize = new System.Drawing.Size(470, 324);
            this.Controls.Add(this.label11);
            this.Controls.Add(this.directoryLimit);
            this.Controls.Add(this.label10);
            this.Controls.Add(this.label9);
            this.Controls.Add(this.photoLimit);
            this.Controls.Add(this.lblProgressMessage);
            this.Controls.Add(this.progress);
            this.Controls.Add(this.btnRunTask);
            this.Controls.Add(this.cbBottomSize);
            this.Controls.Add(this.label8);
            this.Controls.Add(this.cbNameSize);
            this.Controls.Add(this.label7);
            this.Controls.Add(this.cbBrandFontSize);
            this.Controls.Add(this.label6);
            this.Controls.Add(this.cbFonts);
            this.Controls.Add(this.label5);
            this.Controls.Add(this.tbPricePercents);
            this.Controls.Add(this.label4);
            this.Controls.Add(this.tbSkuPrefix);
            this.Controls.Add(this.label3);
            this.Controls.Add(this.btnSelectFolder);
            this.Controls.Add(this.tbFolder);
            this.Controls.Add(this.label2);
            this.Controls.Add(this.tbUrl);
            this.Controls.Add(this.label1);
            this.FormBorderStyle = System.Windows.Forms.FormBorderStyle.FixedSingle;
            this.Name = "MainForm";
            this.Text = "Zappos Leech";
            this.Load += new System.EventHandler(this.MainForm_Load);
            ((System.ComponentModel.ISupportInitialize)(this.errorProvider)).EndInit();
            ((System.ComponentModel.ISupportInitialize)(this.photoLimit)).EndInit();
            ((System.ComponentModel.ISupportInitialize)(this.directoryLimit)).EndInit();
            this.ResumeLayout(false);
            this.PerformLayout();

        }

        #endregion

        private System.Windows.Forms.Label label1;
        private System.Windows.Forms.TextBox tbUrl;
        private System.Windows.Forms.Label label2;
        private System.Windows.Forms.TextBox tbFolder;
        private System.Windows.Forms.Button btnSelectFolder;
        private System.Windows.Forms.Label label3;
        private System.Windows.Forms.TextBox tbSkuPrefix;
        private System.Windows.Forms.Label label4;
        private System.Windows.Forms.TextBox tbPricePercents;
        private System.Windows.Forms.Label label5;
        private System.Windows.Forms.ComboBox cbFonts;
        private System.Windows.Forms.Label label6;
        private System.Windows.Forms.ComboBox cbBrandFontSize;
        private System.Windows.Forms.Label label7;
        private System.Windows.Forms.ComboBox cbNameSize;
        private System.Windows.Forms.Label label8;
        private System.Windows.Forms.ComboBox cbBottomSize;
        private System.Windows.Forms.FolderBrowserDialog dlgTargetFolder;
        private System.Windows.Forms.Button btnRunTask;
        private System.Windows.Forms.ErrorProvider errorProvider;
        private System.Windows.Forms.ProgressBar progress;
        private System.ComponentModel.BackgroundWorker worker;
        private System.Windows.Forms.Label lblProgressMessage;
        private System.Windows.Forms.Label label9;
        private System.Windows.Forms.NumericUpDown photoLimit;
        private System.Windows.Forms.Label label11;
        private System.Windows.Forms.NumericUpDown directoryLimit;
        private System.Windows.Forms.Label label10;
    }
}

