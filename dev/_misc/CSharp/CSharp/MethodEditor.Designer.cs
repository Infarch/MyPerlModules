namespace CSharp
{
    partial class MethodEditor
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
            this.tbMethodName = new System.Windows.Forms.TextBox();
            this.label2 = new System.Windows.Forms.Label();
            this.cbMethodAccessModifier = new System.Windows.Forms.ComboBox();
            this.label3 = new System.Windows.Forms.Label();
            this.rbVoid = new System.Windows.Forms.RadioButton();
            this.rbTyped = new System.Windows.Forms.RadioButton();
            this.cbMethodType = new System.Windows.Forms.ComboBox();
            this.btnCancel = new System.Windows.Forms.Button();
            this.btnOk = new System.Windows.Forms.Button();
            this.errorProvider = new System.Windows.Forms.ErrorProvider(this.components);
            this.label4 = new System.Windows.Forms.Label();
            this.tbMethodComment = new System.Windows.Forms.TextBox();
            this.label5 = new System.Windows.Forms.Label();
            this.lbParameters = new System.Windows.Forms.ListBox();
            this.gbParam = new System.Windows.Forms.GroupBox();
            this.label6 = new System.Windows.Forms.Label();
            this.tbMethodParamName = new System.Windows.Forms.TextBox();
            this.label7 = new System.Windows.Forms.Label();
            this.cbMethodParamType = new System.Windows.Forms.ComboBox();
            this.btnAddMethodParam = new System.Windows.Forms.Button();
            ((System.ComponentModel.ISupportInitialize)(this.errorProvider)).BeginInit();
            this.gbParam.SuspendLayout();
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
            // tbMethodName
            // 
            this.tbMethodName.Location = new System.Drawing.Point(12, 25);
            this.tbMethodName.Name = "tbMethodName";
            this.tbMethodName.Size = new System.Drawing.Size(361, 20);
            this.tbMethodName.TabIndex = 1;
            // 
            // label2
            // 
            this.label2.AutoSize = true;
            this.label2.Location = new System.Drawing.Point(12, 64);
            this.label2.Name = "label2";
            this.label2.Size = new System.Drawing.Size(84, 13);
            this.label2.TabIndex = 2;
            this.label2.Text = "Access modifier:";
            // 
            // cbMethodAccessModifier
            // 
            this.cbMethodAccessModifier.FormattingEnabled = true;
            this.cbMethodAccessModifier.Location = new System.Drawing.Point(12, 80);
            this.cbMethodAccessModifier.Name = "cbMethodAccessModifier";
            this.cbMethodAccessModifier.Size = new System.Drawing.Size(121, 21);
            this.cbMethodAccessModifier.TabIndex = 3;
            // 
            // label3
            // 
            this.label3.AutoSize = true;
            this.label3.Location = new System.Drawing.Point(12, 121);
            this.label3.Name = "label3";
            this.label3.Size = new System.Drawing.Size(65, 13);
            this.label3.TabIndex = 4;
            this.label3.Text = "Return type:";
            // 
            // rbVoid
            // 
            this.rbVoid.AutoSize = true;
            this.rbVoid.Checked = true;
            this.rbVoid.Location = new System.Drawing.Point(12, 137);
            this.rbVoid.Name = "rbVoid";
            this.rbVoid.Size = new System.Drawing.Size(46, 17);
            this.rbVoid.TabIndex = 5;
            this.rbVoid.TabStop = true;
            this.rbVoid.Text = "Void";
            this.rbVoid.UseVisualStyleBackColor = true;
            this.rbVoid.CheckedChanged += new System.EventHandler(this.rbVoid_CheckedChanged);
            // 
            // rbTyped
            // 
            this.rbTyped.AutoSize = true;
            this.rbTyped.Location = new System.Drawing.Point(12, 160);
            this.rbTyped.Name = "rbTyped";
            this.rbTyped.Size = new System.Drawing.Size(73, 17);
            this.rbTyped.TabIndex = 6;
            this.rbTyped.TabStop = true;
            this.rbTyped.Text = "With type:";
            this.rbTyped.UseVisualStyleBackColor = true;
            // 
            // cbMethodType
            // 
            this.cbMethodType.Enabled = false;
            this.cbMethodType.FormattingEnabled = true;
            this.cbMethodType.Location = new System.Drawing.Point(30, 183);
            this.cbMethodType.Name = "cbMethodType";
            this.cbMethodType.Size = new System.Drawing.Size(343, 21);
            this.cbMethodType.TabIndex = 7;
            // 
            // btnCancel
            // 
            this.btnCancel.Location = new System.Drawing.Point(15, 546);
            this.btnCancel.Name = "btnCancel";
            this.btnCancel.Size = new System.Drawing.Size(75, 23);
            this.btnCancel.TabIndex = 14;
            this.btnCancel.Text = "Cancel";
            this.btnCancel.UseVisualStyleBackColor = true;
            this.btnCancel.Click += new System.EventHandler(this.btnCancel_Click);
            // 
            // btnOk
            // 
            this.btnOk.Location = new System.Drawing.Point(301, 546);
            this.btnOk.Name = "btnOk";
            this.btnOk.Size = new System.Drawing.Size(75, 23);
            this.btnOk.TabIndex = 13;
            this.btnOk.Text = "Ok";
            this.btnOk.UseVisualStyleBackColor = true;
            this.btnOk.Click += new System.EventHandler(this.btnOk_Click);
            // 
            // errorProvider
            // 
            this.errorProvider.ContainerControl = this;
            // 
            // label4
            // 
            this.label4.AutoSize = true;
            this.label4.Location = new System.Drawing.Point(12, 423);
            this.label4.Name = "label4";
            this.label4.Size = new System.Drawing.Size(54, 13);
            this.label4.TabIndex = 11;
            this.label4.Text = "Comment:";
            // 
            // tbMethodComment
            // 
            this.tbMethodComment.Location = new System.Drawing.Point(12, 439);
            this.tbMethodComment.Multiline = true;
            this.tbMethodComment.Name = "tbMethodComment";
            this.tbMethodComment.Size = new System.Drawing.Size(361, 91);
            this.tbMethodComment.TabIndex = 12;
            // 
            // label5
            // 
            this.label5.AutoSize = true;
            this.label5.Location = new System.Drawing.Point(12, 224);
            this.label5.Name = "label5";
            this.label5.Size = new System.Drawing.Size(63, 13);
            this.label5.TabIndex = 8;
            this.label5.Text = "Parameters:";
            // 
            // lbParameters
            // 
            this.lbParameters.FormattingEnabled = true;
            this.lbParameters.Location = new System.Drawing.Point(12, 240);
            this.lbParameters.Name = "lbParameters";
            this.lbParameters.SelectionMode = System.Windows.Forms.SelectionMode.None;
            this.lbParameters.Size = new System.Drawing.Size(161, 160);
            this.lbParameters.TabIndex = 9;
            // 
            // gbParam
            // 
            this.gbParam.Controls.Add(this.btnAddMethodParam);
            this.gbParam.Controls.Add(this.cbMethodParamType);
            this.gbParam.Controls.Add(this.label7);
            this.gbParam.Controls.Add(this.tbMethodParamName);
            this.gbParam.Controls.Add(this.label6);
            this.gbParam.Location = new System.Drawing.Point(179, 240);
            this.gbParam.Name = "gbParam";
            this.gbParam.Size = new System.Drawing.Size(194, 163);
            this.gbParam.TabIndex = 10;
            this.gbParam.TabStop = false;
            this.gbParam.Text = "New parameter:";
            // 
            // label6
            // 
            this.label6.AutoSize = true;
            this.label6.Location = new System.Drawing.Point(6, 27);
            this.label6.Name = "label6";
            this.label6.Size = new System.Drawing.Size(38, 13);
            this.label6.TabIndex = 0;
            this.label6.Text = "Name:";
            // 
            // tbMethodParamName
            // 
            this.tbMethodParamName.Location = new System.Drawing.Point(6, 43);
            this.tbMethodParamName.Name = "tbMethodParamName";
            this.tbMethodParamName.Size = new System.Drawing.Size(182, 20);
            this.tbMethodParamName.TabIndex = 1;
            // 
            // label7
            // 
            this.label7.AutoSize = true;
            this.label7.Location = new System.Drawing.Point(6, 78);
            this.label7.Name = "label7";
            this.label7.Size = new System.Drawing.Size(34, 13);
            this.label7.TabIndex = 2;
            this.label7.Text = "Type:";
            // 
            // cbMethodParamType
            // 
            this.cbMethodParamType.FormattingEnabled = true;
            this.cbMethodParamType.Location = new System.Drawing.Point(6, 94);
            this.cbMethodParamType.Name = "cbMethodParamType";
            this.cbMethodParamType.Size = new System.Drawing.Size(182, 21);
            this.cbMethodParamType.TabIndex = 3;
            // 
            // btnAddMethodParam
            // 
            this.btnAddMethodParam.Location = new System.Drawing.Point(113, 130);
            this.btnAddMethodParam.Name = "btnAddMethodParam";
            this.btnAddMethodParam.Size = new System.Drawing.Size(75, 23);
            this.btnAddMethodParam.TabIndex = 4;
            this.btnAddMethodParam.Text = "Add";
            this.btnAddMethodParam.UseVisualStyleBackColor = true;
            this.btnAddMethodParam.Click += new System.EventHandler(this.btnAddMethodParam_Click);
            // 
            // MethodEditor
            // 
            this.AutoScaleDimensions = new System.Drawing.SizeF(6F, 13F);
            this.AutoScaleMode = System.Windows.Forms.AutoScaleMode.Font;
            this.ClientSize = new System.Drawing.Size(433, 581);
            this.Controls.Add(this.gbParam);
            this.Controls.Add(this.lbParameters);
            this.Controls.Add(this.label5);
            this.Controls.Add(this.tbMethodComment);
            this.Controls.Add(this.label4);
            this.Controls.Add(this.btnOk);
            this.Controls.Add(this.btnCancel);
            this.Controls.Add(this.cbMethodType);
            this.Controls.Add(this.rbTyped);
            this.Controls.Add(this.rbVoid);
            this.Controls.Add(this.label3);
            this.Controls.Add(this.cbMethodAccessModifier);
            this.Controls.Add(this.label2);
            this.Controls.Add(this.tbMethodName);
            this.Controls.Add(this.label1);
            this.FormBorderStyle = System.Windows.Forms.FormBorderStyle.FixedDialog;
            this.MaximizeBox = false;
            this.MinimizeBox = false;
            this.Name = "MethodEditor";
            this.Text = "Method editor";
            this.Load += new System.EventHandler(this.MethodEditor_Load);
            ((System.ComponentModel.ISupportInitialize)(this.errorProvider)).EndInit();
            this.gbParam.ResumeLayout(false);
            this.gbParam.PerformLayout();
            this.ResumeLayout(false);
            this.PerformLayout();

        }

        #endregion

        private System.Windows.Forms.Label label1;
        private System.Windows.Forms.TextBox tbMethodName;
        private System.Windows.Forms.Label label2;
        private System.Windows.Forms.ComboBox cbMethodAccessModifier;
        private System.Windows.Forms.Label label3;
        private System.Windows.Forms.RadioButton rbVoid;
        private System.Windows.Forms.RadioButton rbTyped;
        private System.Windows.Forms.ComboBox cbMethodType;
        private System.Windows.Forms.Button btnCancel;
        private System.Windows.Forms.Button btnOk;
        private System.Windows.Forms.ErrorProvider errorProvider;
        private System.Windows.Forms.TextBox tbMethodComment;
        private System.Windows.Forms.Label label4;
        private System.Windows.Forms.GroupBox gbParam;
        private System.Windows.Forms.Button btnAddMethodParam;
        private System.Windows.Forms.ComboBox cbMethodParamType;
        private System.Windows.Forms.Label label7;
        private System.Windows.Forms.TextBox tbMethodParamName;
        private System.Windows.Forms.Label label6;
        private System.Windows.Forms.ListBox lbParameters;
        private System.Windows.Forms.Label label5;
    }
}