using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.Linq;
using System.Text;
using System.Windows.Forms;

namespace BAKi
{
    public partial class DataOverviewForm : Form
    {
        private Category root;

        public DataOverviewForm(Category root)
            : this()
        {
            this.root = root;
        }

        public DataOverviewForm()
        {
            InitializeComponent();
        }

        private void DataOverviewForm_Load(object sender, EventArgs e)
        {
            TreeNode rootNode = treeView.Nodes.Add("BAKI.INFO");
            foreach (Member m in root.Children)
            {
                AddMember(rootNode, m);
            }

        }

        private void AddMember(TreeNode parent, Member m)
        {
            TreeNode node = parent.Nodes.Add(m.Name);
            if (m is Category)
            {
                foreach (Member m1 in m.Children)
                {
                    AddMember(node, m1);
                }
            }
            else
            {
                Leaf l = (Leaf)m;

                node.Nodes.Add(l.Address);
                node.Nodes.Add(l.Coords);

                foreach (String x in l.Phones)
                {
                    node.Nodes.Add(x);
                }
                foreach (String x in l.Sites)
                {
                    node.Nodes.Add(x);
                }
            }
        }

    }
}
