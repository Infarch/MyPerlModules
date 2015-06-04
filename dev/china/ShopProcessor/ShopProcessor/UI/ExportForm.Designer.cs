namespace ShopProcessor.UI
{
    partial class ExportForm
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
            this.lbStatus = new System.Windows.Forms.Label();
            this.checker = new System.ComponentModel.BackgroundWorker();
            this.btnExport = new System.Windows.Forms.Button();
            this.btnCancel = new System.Windows.Forms.Button();
            this.tbCodePrefix = new System.Windows.Forms.TextBox();
            this.tbCodeStart = new System.Windows.Forms.TextBox();
            this.label1 = new System.Windows.Forms.Label();
            this.progress = new System.Windows.Forms.ProgressBar();
            this.exporter = new System.ComponentModel.BackgroundWorker();
            this.SuspendLayout();
            // 
            // lbStatus
            // 
            this.lbStatus.AutoSize = true;
            this.lbStatus.Location = new System.Drawing.Point(12, 9);
            this.lbStatus.Name = "lbStatus";
            this.lbStatus.Size = new System.Drawing.Size(38, 13);
            this.lbStatus.TabIndex = 0;
            this.lbStatus.Text = "Wait...";
            // 
            // checker
            // 
            this.checker.WorkerReportsProgress = true;
            this.checker.WorkerSupportsCancellation = true;
            this.checker.DoWork += new System.ComponentModel.DoWorkEventHandler(this.checker_DoWork);
            this.checker.ProgressChanged += new System.ComponentModel.ProgressChangedEventHandler(this.checker_ProgressChanged);
            // 
            // btnExport
            // 
            this.btnExport.Enabled = false;
            this.btnExport.Location = new System.Drawing.Point(107, 227);
            this.btnExport.Name = "btnExport";
            this.btnExport.Size = new System.Drawing.Size(75, 23);
            this.btnExport.TabIndex = 1;
            this.btnExport.Text = "Export";
            this.btnExport.UseVisualStyleBackColor = true;
            this.btnExport.Click += new System.EventHandler(this.btnExport_Click);
            // 
            // btnCancel
            // 
            this.btnCancel.Location = new System.Drawing.Point(197, 227);
            this.btnCancel.Name = "btnCancel";
            this.btnCancel.Size = new System.Drawing.Size(75, 23);
            this.btnCancel.TabIndex = 2;
            this.btnCancel.Text = "Close";
            this.btnCancel.UseVisualStyleBackColor = true;
            this.btnCancel.Click += new System.EventHandler(this.btnCancel_Click);
            // 
            // tbCodePrefix
            // 
            this.tbCodePrefix.Location = new System.Drawing.Point(12, 115);
            this.tbCodePrefix.Name = "tbCodePrefix";
            this.tbCodePrefix.Size = new System.Drawing.Size(56, 20);
            this.tbCodePrefix.TabIndex = 3;
            this.tbCodePrefix.Text = "X-";
            this.tbCodePrefix.Validating += new System.ComponentModel.CancelEventHandler(this.tbCodePrefix_Validating);
            // 
            // tbCodeStart
            // 
            this.tbCodeStart.Location = new System.Drawing.Point(74, 115);
            this.tbCodeStart.Name = "tbCodeStart";
            this.tbCodeStart.Size = new System.Drawing.Size(57, 20);
            this.tbCodeStart.TabIndex = 4;
            this.tbCodeStart.Text = "1";
            this.tbCodeStart.Validating += new System.ComponentModel.CancelEventHandler(this.tbCodeStart_Validating);
            // 
            // label1
            // 
            this.label1.AutoSize = true;
            this.label1.Location = new System.Drawing.Point(15, 147);
            this.label1.Name = "label1";
            this.label1.Size = new System.Drawing.Size(226, 26);
            this.label1.TabIndex = 5;
            this.label1.Text = "* This will be used for product code generation\r\nwhen you don\'t enter it manually" +
                ".";
            // 
            // progress
            // 
            this.progress.Location = new System.Drawing.Point(12, 185);
            this.progress.Name = "progress";
            this.progress.Size = new System.Drawing.Size(260, 23);
            this.progress.TabIndex = 6;
            this.progress.Visible = false;
            // 
            // exporter
            // 
            this.exporter.WorkerReportsProgress = true;
            this.exporter.WorkerSupportsCancellation = true;
            this.exporter.DoWork += new System.ComponentModel.DoWorkEventHandler(this.exporter_DoWork);
            this.exporter.ProgressChanged += new System.ComponentModel.ProgressChangedEventHandler(this.exporter_ProgressChanged);
            this.exporter.RunWorkerCompleted += new System.ComponentModel.RunWorkerCompletedEventHandler(this.exporter_RunWorkerCompleted);
            // 
            // ExportForm
            // 
            this.AutoScaleDimensions = new System.Drawing.SizeF(6F, 13F);
            this.AutoScaleMode = System.Windows.Forms.AutoScaleMode.Font;
            this.ClientSize = new System.Drawing.Size(284, 262);
            this.Controls.Add(this.progress);
            this.Controls.Add(this.label1);
            this.Controls.Add(this.tbCodeStart);
            this.Controls.Add(this.tbCodePrefix);
            this.Controls.Add(this.btnCancel);
            this.Controls.Add(this.btnExport);
            this.Controls.Add(this.lbStatus);
            this.FormBorderStyle = System.Windows.Forms.FormBorderStyle.FixedDialog;
            this.MaximizeBox = false;
            this.MinimizeBox = false;
            this.Name = "ExportForm";
            this.Text = "Export";
            this.FormClosing += new System.Windows.Forms.FormClosingEventHandler(this.ExportForm_FormClosing);
            this.Load += new System.EventHandler(this.ExportForm_Load);
            this.ResumeLayout(false);
            this.PerformLayout();

        }

        #endregion

        private System.Windows.Forms.Label lbStatus;
        private System.ComponentModel.BackgroundWorker checker;
        private System.Windows.Forms.Button btnExport;
        private System.Windows.Forms.Button btnCancel;
        private System.Windows.Forms.TextBox tbCodePrefix;
        private System.Windows.Forms.TextBox tbCodeStart;
        private System.Windows.Forms.Label label1;
        private System.Windows.Forms.ProgressBar progress;
        private System.ComponentModel.BackgroundWorker exporter;
    }
}