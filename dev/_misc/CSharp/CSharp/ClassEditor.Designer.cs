namespace CSharp
{
    partial class ClassEditor
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
            this.tbClassName = new System.Windows.Forms.TextBox();
            this.label2 = new System.Windows.Forms.Label();
            this.cbClassAncestor = new System.Windows.Forms.ComboBox();
            this.label3 = new System.Windows.Forms.Label();
            this.tbClassAlias = new System.Windows.Forms.TextBox();
            this.label4 = new System.Windows.Forms.Label();
            this.tbClassComment = new System.Windows.Forms.TextBox();
            this.btnOk = new System.Windows.Forms.Button();
            this.btnCancel = new System.Windows.Forms.Button();
            this.label5 = new System.Windows.Forms.Label();
            this.cbClassAccessModifier = new System.Windows.Forms.ComboBox();
            this.errorProvider = new System.Windows.Forms.ErrorProvider(this.components);
            ((System.ComponentModel.ISupportInitialize)(this.errorProvider)).BeginInit();
            this.SuspendLayout();
            // 
            // label1
            // 
            this.label1.AutoSize = true;
            this.label1.Location = new System.Drawing.Point(12, 9);
            this.label1.Name = "label1";
            this.label1.Size = new System.Drawing.Size(38, 13);
            this.label1.TabIndex = 0;
            this.label1.Text = "Name:";
            // 
            // tbClassName
            // 
            this.tbClassName.Location = new System.Drawing.Point(12, 25);
            this.tbClassName.Name = "tbClassName";
            this.tbClassName.Size = new System.Drawing.Size(455, 20);
            this.tbClassName.TabIndex = 1;
            // 
            // label2
            // 
            this.label2.AutoSize = true;
            this.label2.Location = new System.Drawing.Point(15, 175);
            this.label2.Name = "label2";
            this.label2.Size = new System.Drawing.Size(52, 13);
            this.label2.TabIndex = 6;
            this.label2.Text = "Ancestor:";
            // 
            // cbClassAncestor
            // 
            this.cbClassAncestor.FormattingEnabled = true;
            this.cbClassAncestor.Location = new System.Drawing.Point(15, 191);
            this.cbClassAncestor.Name = "cbClassAncestor";
            this.cbClassAncestor.Size = new System.Drawing.Size(455, 21);
            this.cbClassAncestor.TabIndex = 7;
            // 
            // label3
            // 
            this.label3.AutoSize = true;
            this.label3.Location = new System.Drawing.Point(12, 59);
            this.label3.Name = "label3";
            this.label3.Size = new System.Drawing.Size(32, 13);
            this.label3.TabIndex = 2;
            this.label3.Text = "Alias:";
            // 
            // tbClassAlias
            // 
            this.tbClassAlias.Location = new System.Drawing.Point(12, 75);
            this.tbClassAlias.Name = "tbClassAlias";
            this.tbClassAlias.Size = new System.Drawing.Size(179, 20);
            this.tbClassAlias.TabIndex = 3;
            // 
            // label4
            // 
            this.label4.AutoSize = true;
            this.label4.Location = new System.Drawing.Point(15, 232);
            this.label4.Name = "label4";
            this.label4.Size = new System.Drawing.Size(54, 13);
            this.label4.TabIndex = 8;
            this.label4.Text = "Comment:";
            // 
            // tbClassComment
            // 
            this.tbClassComment.Location = new System.Drawing.Point(15, 248);
            this.tbClassComment.Multiline = true;
            this.tbClassComment.Name = "tbClassComment";
            this.tbClassComment.Size = new System.Drawing.Size(452, 79);
            this.tbClassComment.TabIndex = 9;
            // 
            // btnOk
            // 
            this.btnOk.Location = new System.Drawing.Point(392, 352);
            this.btnOk.Name = "btnOk";
            this.btnOk.Size = new System.Drawing.Size(75, 23);
            this.btnOk.TabIndex = 11;
            this.btnOk.Text = "Ok";
            this.btnOk.UseVisualStyleBackColor = true;
            this.btnOk.Click += new System.EventHandler(this.btnOk_Click);
            // 
            // btnCancel
            // 
            this.btnCancel.Location = new System.Drawing.Point(15, 352);
            this.btnCancel.Name = "btnCancel";
            this.btnCancel.Size = new System.Drawing.Size(75, 23);
            this.btnCancel.TabIndex = 10;
            this.btnCancel.Text = "Cancel";
            this.btnCancel.UseVisualStyleBackColor = true;
            this.btnCancel.Click += new System.EventHandler(this.btnCancel_Click);
            // 
            // label5
            // 
            this.label5.AutoSize = true;
            this.label5.Location = new System.Drawing.Point(15, 118);
            this.label5.Name = "label5";
            this.label5.Size = new System.Drawing.Size(84, 13);
            this.label5.TabIndex = 4;
            this.label5.Text = "Access modifier:";
            // 
            // cbClassAccessModifier
            // 
            this.cbClassAccessModifier.FormattingEnabled = true;
            this.cbClassAccessModifier.Location = new System.Drawing.Point(15, 134);
            this.cbClassAccessModifier.Name = "cbClassAccessModifier";
            this.cbClassAccessModifier.Size = new System.Drawing.Size(121, 21);
            this.cbClassAccessModifier.TabIndex = 5;
            // 
            // errorProvider
            // 
            this.errorProvider.ContainerControl = this;
            // 
            // ClassEditor
            // 
            this.AutoScaleDimensions = new System.Drawing.SizeF(6F, 13F);
            this.AutoScaleMode = System.Windows.Forms.AutoScaleMode.Font;
            this.ClientSize = new System.Drawing.Size(541, 384);
            this.Controls.Add(this.cbClassAccessModifier);
            this.Controls.Add(this.label5);
            this.Controls.Add(this.btnCancel);
            this.Controls.Add(this.btnOk);
            this.Controls.Add(this.tbClassComment);
            this.Controls.Add(this.label4);
            this.Controls.Add(this.tbClassAlias);
            this.Controls.Add(this.label3);
            this.Controls.Add(this.cbClassAncestor);
            this.Controls.Add(this.label2);
            this.Controls.Add(this.tbClassName);
            this.Controls.Add(this.label1);
            this.FormBorderStyle = System.Windows.Forms.FormBorderStyle.FixedDialog;
            this.MaximizeBox = false;
            this.MinimizeBox = false;
            this.Name = "ClassEditor";
            this.Text = "Class editor";
            this.Load += new System.EventHandler(this.frmClassEditor_Load);
            ((System.ComponentModel.ISupportInitialize)(this.errorProvider)).EndInit();
            this.ResumeLayout(false);
            this.PerformLayout();

        }

        #endregion

        private System.Windows.Forms.Label label1;
        private System.Windows.Forms.TextBox tbClassName;
        private System.Windows.Forms.Label label2;
        private System.Windows.Forms.ComboBox cbClassAncestor;
        private System.Windows.Forms.Label label3;
        private System.Windows.Forms.TextBox tbClassAlias;
        private System.Windows.Forms.Label label4;
        private System.Windows.Forms.TextBox tbClassComment;
        private System.Windows.Forms.Button btnOk;
        private System.Windows.Forms.Button btnCancel;
        private System.Windows.Forms.Label label5;
        private System.Windows.Forms.ComboBox cbClassAccessModifier;
        private System.Windows.Forms.ErrorProvider errorProvider;
    }
}