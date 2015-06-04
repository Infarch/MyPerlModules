using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.Linq;
using System.Text;
using System.Windows.Forms;
using System.IO;
using System.Net;

namespace SimpleBot
{
    public partial class Form1 : Form
    {
        Random rnd = new Random();

        public Form1()
        {
            InitializeComponent();
        }

        private void btnLoad_Click(object sender, EventArgs e)
        {
            if (dlgOpen.ShowDialog() == DialogResult.OK)
            {
                try
                {
                    using (TextReader reader = new StreamReader(dlgOpen.FileName))
                    {
                        String input;
                        while ((input = reader.ReadLine()) != null)
                        {
                            lbLinks.Items.Add(input);
                        }
                    }

                }
                catch (Exception exc)
                {
                    MessageBox.Show("Error reading file");
                }
            }
        }

        private void btnStart_Click(object sender, EventArgs e)
        {
            if (lbLinks.Items.Count == 0)
            {
                MessageBox.Show("Your list is empty");
                return;
            }

            foreach (Control c in pnTools.Controls)
            {
                c.Enabled = false;
            }
            
            RunTimer();
        }

        private void RunTimer()
        {
            while(pnBrowsers.Controls.Count > 0)
            {
                Control c = pnBrowsers.Controls[0];
                pnBrowsers.Controls.Remove(c);
                c.Dispose();
            }

            if (lbLinks.Items.Count == 0)
            {
                foreach (Control c in pnTools.Controls)
                {
                    c.Enabled = true;
                }
                return;
            }

            int limit = 21;
            lbLinks.BeginUpdate();
            while (limit-- > 0)
            {
                if (lbLinks.Items.Count > 0)
                {
                    String url = (String)lbLinks.Items[0];
                    lbLinks.Items.RemoveAt(0);
                    WebBrowser browser = new WebBrowser();
                    browser.Dock = DockStyle.None;
                    browser.Width = 250;
                    browser.Height = 200;
                    pnBrowsers.Controls.Add(browser);
                    browser.ScriptErrorsSuppressed = true;

                    browser.Navigate(url);
                }
            }
            lbLinks.EndUpdate();
            int sec = rnd.Next(25, 35);
            timer.Interval = sec * 1000;
            timer.Start();
        }

        private void timer_Tick(object sender, EventArgs e)
        {
            RunTimer();
        }
    }
}
