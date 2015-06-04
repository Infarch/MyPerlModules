using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.Linq;
using System.Text;
using System.Windows.Forms;

namespace ShopProcessor.UI
{
    public partial class RenameProductForm : Form
    {
        public RenameProductForm()
        {
            InitializeComponent();
        }

        private String newtext;

        public String NewText
        {
            get { return newtext; }
            set { newtext = value; }
        }

        public DialogResult ShowDialog(IWin32Window owner, String text)
        {
            this.textBox.Text = text;
            return base.ShowDialog(owner);
        }

        private void btnOk_Click(object sender, EventArgs e)
        {
            this.NewText = textBox.Text;
            this.DialogResult = DialogResult.OK;
        }

        private void btnCancel_Click(object sender, EventArgs e)
        {
            this.DialogResult = DialogResult.Cancel;
        }
    }
}
