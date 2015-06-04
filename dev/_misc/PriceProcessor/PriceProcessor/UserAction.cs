using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Drawing;
using System.Data;
using System.Linq;
using System.Text;
using System.Windows.Forms;

namespace PriceProcessor
{
    public partial class UserAction : UserControl
    {
        bool isSpecial;

        public bool IsSpecial
        {
            get { return isSpecial; }
            set { isSpecial = value; }
        }
        public string LabelText
        {
            get { return label.Text; }
            set { label.Text = value; }
        }

        public UserAction()
        {
            InitializeComponent();
        }

        public event EventHandler ButtonClick;

        public UserAction(string labeltext, bool enabled, Action action)
            : this()
        {
            LabelText = labeltext;
            Enabled = enabled;
            if (action != null)
            {
                ButtonClick += new EventHandler((sender, args) =>
                {
                    action();
                });
            }
        }

        private void btnStart_Click(object sender, EventArgs e)
        {
            if (ButtonClick != null) ButtonClick(sender, e);
        }
    }
}
