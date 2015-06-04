using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.Linq;
using System.Text;
using System.Windows.Forms;

namespace BakiMT
{
    public partial class ViewForm : Form
    {
        CategoryRoot root;

        public ViewForm(CategoryRoot root)
        {
            this.root = root;
            InitializeComponent();
        }

        private void ViewForm_Load(object sender, EventArgs e)
        {
            TreeNode n = treeView.Nodes.Add(root.Name);
            foreach (AbstractMember m in root.Children)
            {
                AddMember(n, m);
            }
        }

        private void AddMember(TreeNode node, AbstractMember m)
        {
            TreeNode n = node.Nodes.Add(m.Name);
            foreach (AbstractMember m1 in m.Children)
            {
                AddMember(n, m1);
            }
            if (m is Product && !m.Unprocessed)
            {
                Product p = m as Product;
                n.Nodes.Add(p.Address);
                n.Nodes.Add(p.Coords);
                foreach (String s in p.Phones)
                {
                    n.Nodes.Add(s);
                }
                foreach (String s in p.Emails)
                {
                    n.Nodes.Add(s);
                }
                foreach (String s in p.Sites)
                {
                    n.Nodes.Add(s);
                }
            }
        }
    }
}
