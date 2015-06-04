namespace PriceProcessor
{
    partial class UserAction
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

        #region Component Designer generated code

        /// <summary> 
        /// Required method for Designer support - do not modify 
        /// the contents of this method with the code editor.
        /// </summary>
        private void InitializeComponent()
        {
            this.pnHolder = new System.Windows.Forms.Panel();
            this.label = new System.Windows.Forms.Label();
            this.btnStart = new System.Windows.Forms.Button();
            this.pnHolder.SuspendLayout();
            this.SuspendLayout();
            // 
            // pnHolder
            // 
            this.pnHolder.BorderStyle = System.Windows.Forms.BorderStyle.FixedSingle;
            this.pnHolder.Controls.Add(this.label);
            this.pnHolder.Controls.Add(this.btnStart);
            this.pnHolder.Dock = System.Windows.Forms.DockStyle.Fill;
            this.pnHolder.Location = new System.Drawing.Point(0, 0);
            this.pnHolder.Name = "pnHolder";
            this.pnHolder.Size = new System.Drawing.Size(306, 32);
            this.pnHolder.TabIndex = 0;
            // 
            // label
            // 
            this.label.AutoSize = true;
            this.label.Location = new System.Drawing.Point(38, 9);
            this.label.Name = "label";
            this.label.Size = new System.Drawing.Size(16, 13);
            this.label.TabIndex = 1;
            this.label.Text = "...";
            // 
            // btnStart
            // 
            this.btnStart.FlatStyle = System.Windows.Forms.FlatStyle.Flat;
            this.btnStart.Image = global::PriceProcessor.Properties.Resources.page_next;
            this.btnStart.Location = new System.Drawing.Point(3, 3);
            this.btnStart.Name = "btnStart";
            this.btnStart.Size = new System.Drawing.Size(29, 25);
            this.btnStart.TabIndex = 0;
            this.btnStart.UseVisualStyleBackColor = true;
            this.btnStart.Click += new System.EventHandler(this.btnStart_Click);
            // 
            // UserAction
            // 
            this.AutoScaleDimensions = new System.Drawing.SizeF(6F, 13F);
            this.AutoScaleMode = System.Windows.Forms.AutoScaleMode.Font;
            this.Controls.Add(this.pnHolder);
            this.Name = "UserAction";
            this.Size = new System.Drawing.Size(306, 32);
            this.pnHolder.ResumeLayout(false);
            this.pnHolder.PerformLayout();
            this.ResumeLayout(false);

        }

        #endregion

        private System.Windows.Forms.Panel pnHolder;
        private System.Windows.Forms.Label label;
        private System.Windows.Forms.Button btnStart;
    }
}
