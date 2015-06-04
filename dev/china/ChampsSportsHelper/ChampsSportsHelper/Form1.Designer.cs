namespace ChampsSportsHelper
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
            this.btnStartStop = new System.Windows.Forms.Button();
            this.label1 = new System.Windows.Forms.Label();
            this.lblPendingCount = new System.Windows.Forms.Label();
            this.label2 = new System.Windows.Forms.Label();
            this.lblProcessedModels = new System.Windows.Forms.Label();
            this.timerInfo = new System.Windows.Forms.Timer(this.components);
            this.btnExport = new System.Windows.Forms.Button();
            this.label3 = new System.Windows.Forms.Label();
            this.tbMainCategory = new System.Windows.Forms.TextBox();
            this.progressExport = new System.Windows.Forms.ProgressBar();
            this.label4 = new System.Windows.Forms.Label();
            this.lblFailedCount = new System.Windows.Forms.Label();
            this.label5 = new System.Windows.Forms.Label();
            this.label6 = new System.Windows.Forms.Label();
            this.tbAdditionalCategories = new System.Windows.Forms.TextBox();
            this.label7 = new System.Windows.Forms.Label();
            this.tbPriceMultiplier = new System.Windows.Forms.TextBox();
            this.label8 = new System.Windows.Forms.Label();
            this.tbPriceAdd = new System.Windows.Forms.TextBox();
            this.label9 = new System.Windows.Forms.Label();
            this.SuspendLayout();
            // 
            // btnStartStop
            // 
            this.btnStartStop.Location = new System.Drawing.Point(379, 12);
            this.btnStartStop.Name = "btnStartStop";
            this.btnStartStop.Size = new System.Drawing.Size(96, 23);
            this.btnStartStop.TabIndex = 0;
            this.btnStartStop.Text = "Start monitoring";
            this.btnStartStop.UseVisualStyleBackColor = true;
            this.btnStartStop.Click += new System.EventHandler(this.btnStartStop_Click);
            // 
            // label1
            // 
            this.label1.AutoSize = true;
            this.label1.Location = new System.Drawing.Point(12, 17);
            this.label1.Name = "label1";
            this.label1.Size = new System.Drawing.Size(85, 13);
            this.label1.TabIndex = 1;
            this.label1.Text = "Pending models:";
            // 
            // lblPendingCount
            // 
            this.lblPendingCount.AutoSize = true;
            this.lblPendingCount.Location = new System.Drawing.Point(114, 17);
            this.lblPendingCount.Name = "lblPendingCount";
            this.lblPendingCount.Size = new System.Drawing.Size(13, 13);
            this.lblPendingCount.TabIndex = 2;
            this.lblPendingCount.Text = "0";
            // 
            // label2
            // 
            this.label2.AutoSize = true;
            this.label2.Location = new System.Drawing.Point(12, 40);
            this.label2.Name = "label2";
            this.label2.Size = new System.Drawing.Size(96, 13);
            this.label2.TabIndex = 3;
            this.label2.Text = "Processed models:";
            // 
            // lblProcessedModels
            // 
            this.lblProcessedModels.AutoSize = true;
            this.lblProcessedModels.Location = new System.Drawing.Point(114, 40);
            this.lblProcessedModels.Name = "lblProcessedModels";
            this.lblProcessedModels.Size = new System.Drawing.Size(13, 13);
            this.lblProcessedModels.TabIndex = 4;
            this.lblProcessedModels.Text = "0";
            // 
            // timerInfo
            // 
            this.timerInfo.Interval = 1000;
            this.timerInfo.Tick += new System.EventHandler(this.timerInfo_Tick);
            // 
            // btnExport
            // 
            this.btnExport.Enabled = false;
            this.btnExport.Location = new System.Drawing.Point(374, 304);
            this.btnExport.Name = "btnExport";
            this.btnExport.Size = new System.Drawing.Size(96, 23);
            this.btnExport.TabIndex = 5;
            this.btnExport.Text = "Export";
            this.btnExport.UseVisualStyleBackColor = true;
            this.btnExport.Click += new System.EventHandler(this.btnExport_Click);
            // 
            // label3
            // 
            this.label3.AutoSize = true;
            this.label3.Location = new System.Drawing.Point(9, 134);
            this.label3.Name = "label3";
            this.label3.Size = new System.Drawing.Size(103, 13);
            this.label3.TabIndex = 6;
            this.label3.Text = "Main category name";
            // 
            // tbMainCategory
            // 
            this.tbMainCategory.Location = new System.Drawing.Point(12, 150);
            this.tbMainCategory.Name = "tbMainCategory";
            this.tbMainCategory.Size = new System.Drawing.Size(463, 20);
            this.tbMainCategory.TabIndex = 7;
            this.tbMainCategory.Text = "Кроссовки из США - оригиналы";
            // 
            // progressExport
            // 
            this.progressExport.Location = new System.Drawing.Point(12, 333);
            this.progressExport.Name = "progressExport";
            this.progressExport.Size = new System.Drawing.Size(458, 23);
            this.progressExport.TabIndex = 8;
            this.progressExport.Visible = false;
            // 
            // label4
            // 
            this.label4.AutoSize = true;
            this.label4.Location = new System.Drawing.Point(12, 62);
            this.label4.Name = "label4";
            this.label4.Size = new System.Drawing.Size(74, 13);
            this.label4.TabIndex = 9;
            this.label4.Text = "Failed models:";
            // 
            // lblFailedCount
            // 
            this.lblFailedCount.AutoSize = true;
            this.lblFailedCount.Location = new System.Drawing.Point(114, 62);
            this.lblFailedCount.Name = "lblFailedCount";
            this.lblFailedCount.Size = new System.Drawing.Size(13, 13);
            this.lblFailedCount.TabIndex = 10;
            this.lblFailedCount.Text = "0";
            // 
            // label5
            // 
            this.label5.AutoSize = true;
            this.label5.Font = new System.Drawing.Font("Microsoft Sans Serif", 8.25F, System.Drawing.FontStyle.Underline, System.Drawing.GraphicsUnit.Point, ((byte)(204)));
            this.label5.Location = new System.Drawing.Point(12, 96);
            this.label5.Name = "label5";
            this.label5.Size = new System.Drawing.Size(79, 13);
            this.label5.TabIndex = 11;
            this.label5.Text = "Export settings:";
            // 
            // label6
            // 
            this.label6.AutoSize = true;
            this.label6.Location = new System.Drawing.Point(12, 188);
            this.label6.Name = "label6";
            this.label6.Size = new System.Drawing.Size(337, 13);
            this.label6.TabIndex = 12;
            this.label6.Text = "Additional categories IDs (comma or space - separated list of numbers)";
            // 
            // tbAdditionalCategories
            // 
            this.tbAdditionalCategories.Location = new System.Drawing.Point(12, 204);
            this.tbAdditionalCategories.Name = "tbAdditionalCategories";
            this.tbAdditionalCategories.Size = new System.Drawing.Size(463, 20);
            this.tbAdditionalCategories.TabIndex = 13;
            // 
            // label7
            // 
            this.label7.AutoSize = true;
            this.label7.Location = new System.Drawing.Point(12, 244);
            this.label7.Name = "label7";
            this.label7.Size = new System.Drawing.Size(77, 13);
            this.label7.TabIndex = 14;
            this.label7.Text = "Price multiplier:";
            // 
            // tbPriceMultiplier
            // 
            this.tbPriceMultiplier.Location = new System.Drawing.Point(95, 241);
            this.tbPriceMultiplier.Name = "tbPriceMultiplier";
            this.tbPriceMultiplier.Size = new System.Drawing.Size(50, 20);
            this.tbPriceMultiplier.TabIndex = 15;
            this.tbPriceMultiplier.TextAlign = System.Windows.Forms.HorizontalAlignment.Right;
            // 
            // label8
            // 
            this.label8.AutoSize = true;
            this.label8.Location = new System.Drawing.Point(168, 244);
            this.label8.Name = "label8";
            this.label8.Size = new System.Drawing.Size(67, 13);
            this.label8.TabIndex = 16;
            this.label8.Text = "Add to price:";
            // 
            // tbPriceAdd
            // 
            this.tbPriceAdd.Location = new System.Drawing.Point(241, 241);
            this.tbPriceAdd.Name = "tbPriceAdd";
            this.tbPriceAdd.Size = new System.Drawing.Size(53, 20);
            this.tbPriceAdd.TabIndex = 17;
            this.tbPriceAdd.TextAlign = System.Windows.Forms.HorizontalAlignment.Right;
            // 
            // label9
            // 
            this.label9.AutoSize = true;
            this.label9.Location = new System.Drawing.Point(12, 267);
            this.label9.Name = "label9";
            this.label9.Size = new System.Drawing.Size(284, 13);
            this.label9.TabIndex = 18;
            this.label9.Text = "(the two price modifiers above will be applied to USD price)";
            // 
            // Form1
            // 
            this.AutoScaleDimensions = new System.Drawing.SizeF(6F, 13F);
            this.AutoScaleMode = System.Windows.Forms.AutoScaleMode.Font;
            this.ClientSize = new System.Drawing.Size(485, 537);
            this.Controls.Add(this.label9);
            this.Controls.Add(this.tbPriceAdd);
            this.Controls.Add(this.label8);
            this.Controls.Add(this.tbPriceMultiplier);
            this.Controls.Add(this.label7);
            this.Controls.Add(this.tbAdditionalCategories);
            this.Controls.Add(this.label6);
            this.Controls.Add(this.label5);
            this.Controls.Add(this.lblFailedCount);
            this.Controls.Add(this.label4);
            this.Controls.Add(this.progressExport);
            this.Controls.Add(this.tbMainCategory);
            this.Controls.Add(this.label3);
            this.Controls.Add(this.btnExport);
            this.Controls.Add(this.lblProcessedModels);
            this.Controls.Add(this.label2);
            this.Controls.Add(this.lblPendingCount);
            this.Controls.Add(this.label1);
            this.Controls.Add(this.btnStartStop);
            this.FormBorderStyle = System.Windows.Forms.FormBorderStyle.FixedSingle;
            this.MaximizeBox = false;
            this.Name = "Form1";
            this.Text = "ChampsSports helper";
            this.FormClosing += new System.Windows.Forms.FormClosingEventHandler(this.Form1_FormClosing);
            this.FormClosed += new System.Windows.Forms.FormClosedEventHandler(this.Form1_FormClosed);
            this.ResumeLayout(false);
            this.PerformLayout();

        }

        #endregion

        private System.Windows.Forms.Button btnStartStop;
        private System.Windows.Forms.Label label1;
        private System.Windows.Forms.Label lblPendingCount;
        private System.Windows.Forms.Label label2;
        private System.Windows.Forms.Label lblProcessedModels;
        private System.Windows.Forms.Timer timerInfo;
        private System.Windows.Forms.Button btnExport;
        private System.Windows.Forms.Label label3;
        private System.Windows.Forms.TextBox tbMainCategory;
        private System.Windows.Forms.ProgressBar progressExport;
        private System.Windows.Forms.Label label4;
        private System.Windows.Forms.Label lblFailedCount;
        private System.Windows.Forms.Label label5;
        private System.Windows.Forms.Label label6;
        private System.Windows.Forms.TextBox tbAdditionalCategories;
        private System.Windows.Forms.Label label7;
        private System.Windows.Forms.TextBox tbPriceMultiplier;
        private System.Windows.Forms.Label label8;
        private System.Windows.Forms.TextBox tbPriceAdd;
        private System.Windows.Forms.Label label9;
    }
}

