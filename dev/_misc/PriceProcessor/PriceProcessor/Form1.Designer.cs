namespace PriceProcessor
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
            this.dlgOpenDatabase = new System.Windows.Forms.OpenFileDialog();
            this.pnActions = new System.Windows.Forms.FlowLayoutPanel();
            this.dlgOpenCSV = new System.Windows.Forms.OpenFileDialog();
            this.progress = new System.Windows.Forms.ProgressBar();
            this.dlgSaveCSV = new System.Windows.Forms.SaveFileDialog();
            this.SuspendLayout();
            // 
            // dlgOpenDatabase
            // 
            this.dlgOpenDatabase.Filter = "Database files|*.db|All files|*.*";
            this.dlgOpenDatabase.Title = "Open database file";
            // 
            // pnActions
            // 
            this.pnActions.Dock = System.Windows.Forms.DockStyle.Left;
            this.pnActions.Location = new System.Drawing.Point(0, 0);
            this.pnActions.Name = "pnActions";
            this.pnActions.Size = new System.Drawing.Size(415, 262);
            this.pnActions.TabIndex = 1;
            // 
            // dlgOpenCSV
            // 
            this.dlgOpenCSV.Filter = "CSV files|*.csv|All files|*.*";
            this.dlgOpenCSV.Title = "Open a CSV file";
            // 
            // progress
            // 
            this.progress.Location = new System.Drawing.Point(421, 227);
            this.progress.Name = "progress";
            this.progress.Size = new System.Drawing.Size(147, 23);
            this.progress.Style = System.Windows.Forms.ProgressBarStyle.Marquee;
            this.progress.TabIndex = 2;
            this.progress.Visible = false;
            // 
            // dlgSaveCSV
            // 
            this.dlgSaveCSV.Filter = "CSV files|*.csv|All files|*.*";
            this.dlgSaveCSV.Title = "Save CSV file";
            // 
            // MainForm
            // 
            this.AutoScaleDimensions = new System.Drawing.SizeF(6F, 13F);
            this.AutoScaleMode = System.Windows.Forms.AutoScaleMode.Font;
            this.ClientSize = new System.Drawing.Size(580, 262);
            this.Controls.Add(this.progress);
            this.Controls.Add(this.pnActions);
            this.Name = "MainForm";
            this.Text = "Price processor";
            this.FormClosing += new System.Windows.Forms.FormClosingEventHandler(this.MainForm_FormClosing);
            this.Load += new System.EventHandler(this.MainForm_Load);
            this.ResumeLayout(false);

        }

        #endregion

        private System.Windows.Forms.OpenFileDialog dlgOpenDatabase;
        private System.Windows.Forms.FlowLayoutPanel pnActions;
        private System.Windows.Forms.OpenFileDialog dlgOpenCSV;
        private System.Windows.Forms.ProgressBar progress;
        private System.Windows.Forms.SaveFileDialog dlgSaveCSV;
    }
}

