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
    public partial class Reporter : Form
    {
        String msg;

        public Reporter(String message)
        {
            msg = message;
            InitializeComponent();
        }

        private void Reporter_Load(object sender, EventArgs e)
        {
            textBox.Text = msg;
        }
    }
}
