using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Forms;

namespace Picassa
{
    public partial class AddProductForm : Form
    {
        public AddProductForm()
        {
            InitializeComponent();
        }

        public Product Product { get; set; }

        private async void btnRead_Click(object sender, EventArgs e)
        {
            if (String.IsNullOrWhiteSpace(tbURL.Text))
            {
                MessageBox.Show("The URL must not be empty");
                return;
            }

            tbURL.Enabled = false;
            btnRead.Enabled = false;

            try
            {
                Product = await Yuppo.ReadProductTaskAsync(tbURL.Text);
                tbOrgName.Text = Product.Name;
                tbAlbumName.Text = Product.Name;
                tbAlbumName.Enabled = true;
                btnDone.Enabled = true;
            }
            catch (Exception ex)
            {
                MessageBox.Show(ex.Message);
            }

        }

        private void btnDone_Click(object sender, EventArgs e)
        {
            if (String.IsNullOrWhiteSpace(tbAlbumName.Text))
            {
                MessageBox.Show("The album name must not be empty");
                return;
            }

            Product.AlbumName = tbAlbumName.Text;
            this.DialogResult = DialogResult.OK;
        }
    }
}
