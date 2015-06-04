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
    public partial class AbsorbeProductsForm : Form
    {
        private ProductList products;
        private Product absorber;
        private PhotoBinder binder;

        private ProductList checkedItems = new ProductList();



        public ProductList CheckedItems
        {
            get { return checkedItems; }
            set { checkedItems = value; }
        }

        public AbsorbeProductsForm()
        {
            InitializeComponent();


        }

        public DialogResult ShowDialog(IWin32Window owner, Project project, Product absorber)
        {
            this.products = project.Products;
            this.absorber = absorber;

            binder = new PhotoBinder(FileHelper.PathToProject(project));
            picture.DataBindings.Clear();
            picture.DataBindings.Add("Image", binder, "Img");
            
            labelInfo.DataBindings.Clear();
            labelInfo.DataBindings.Add("Text", binder, "InfoText");

            foreach (Product prod in products)
            {
                if (prod != absorber)
                    cbProducts.Items.Add(prod);
            }

            return base.ShowDialog(owner);
        }

        private void cbProducts_SelectedIndexChanged(object sender, EventArgs e)
        {
            CheckedListBox clb = sender as CheckedListBox;
            Product prod = clb.SelectedItem as Product;
            binder.SetProduct(prod);
        }

        private void btnCancel_Click(object sender, EventArgs e)
        {
            this.DialogResult = DialogResult.Cancel;
        }

        private void btnOk_Click(object sender, EventArgs e)
        {
            foreach (Object obj in cbProducts.CheckedItems)
                CheckedItems.Add(obj as Product);
            this.DialogResult = DialogResult.OK;
        }

    }
}
