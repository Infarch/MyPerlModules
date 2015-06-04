using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.Text;
using System.Windows.Forms;
using System.IO;
using System.Net;
using System.Net.Mail;
using System.Text.RegularExpressions;

/*
 *
 * D:\tools\ilmerge\ILMerge.exe /lib:"$(TargetDir)" /t:winexe /targetplatform:v4,"c:\Program Files (x86)\Reference Assemblies\Microsoft\Framework\.NETFramework\v4.0\Profile\Client" /out:"$(TargetPath)" "$(TargetFileName)" zipforge.dll
 * 
 */
namespace KindleAssistant
{
    public partial class Form1 : Form
    {
        
        private enum SourceType { File, String };

        private String fileName;
        private Boolean is_loaded = false;
        private List<Encoding> encodings;
        private List<IContentFilter> filters;
        private String content;
        //private SourceType source;

        private Boolean Loaded
        {
            get { return is_loaded; }
            set { 
                is_loaded = value;
                btnSend.Enabled = is_loaded;
            }
        }

        public Form1()
        {
            InitializeComponent();
        }

        private void btnOpen_Click(object sender, EventArgs e)
        {
            if (dlgOpenFile.ShowDialog() == DialogResult.OK)
            {
                fileName = dlgOpenFile.FileName;
                LoadFile();
            }
        }

        private void LoadFile()
        {
            Encoding enc = GetSelectedEncoding();
            IContentFilter filter = GetSelectedFilter();
            if (enc != null)
            {
                try
                {
                    Loaded = false;
                    richTextBox.Clear();
                    TextReader reader = new StreamReader(fileName, enc);

                    content = filter.Filter(reader.ReadToEnd());
                    reader.Close();

                    int preview_size = 65535;
                    if (content.Length > preview_size)
                    {
                        richTextBox.AppendText(content.Substring(0, preview_size));
                        richTextBox.AppendText("\n\n....<cut>....\n");
                    }
                    else
                    {
                        richTextBox.AppendText(content);
                    }
                    Loaded = true;
                    //source = SourceType.File;
                }
                catch (Exception ex)
                {
                    Loaded = false;
                    MessageBox.Show(ex.Message);
                }
            }
            else
            {
                MessageBox.Show("Please select an encoding from list");
            }

        }

        private IContentFilter GetSelectedFilter()
        {
            return (IContentFilter)cbFilter.SelectedValue;
        }

        private Encoding GetSelectedEncoding()
        {
            return (Encoding)cbEncoding.SelectedValue;
        }

        private void Form1_Load(object sender, EventArgs e)
        {
            // initialize fields
            PopulateEncodingList();
            PopulateFilterList();
            LoadSettings();

            // setup data bindings
            cbEncoding.DataSource = encodings;
            cbEncoding.DisplayMember = "WebName";

            cbFilter.DataSource = filters;
            cbFilter.DisplayMember = "Name";

            // setup tips
            new ToolTip().SetToolTip(cbEncoding, "Encoding of the original document");
            new ToolTip().SetToolTip(cbFilter, "Filter for the original document.\nUseful for HTML documents.");
        }

        private void PopulateFilterList()
        {
            filters = new List<IContentFilter>();
            filters.Add(new EmptyFilter());
            filters.Add(new LibRuFilter());
        }

        private void PopulateEncodingList()
        {
            encodings = new List<Encoding>();
            encodings.Add(Encoding.UTF8);
            encodings.Add(Encoding.GetEncoding(1251));
        }

        private void cbEncoding_SelectedIndexChanged(object sender, EventArgs e)
        {
            if (Loaded) LoadFile();
        }

        private void Form1_FormClosing(object sender, FormClosingEventArgs e)
        {
            SaveSettings();

        }

        private void SaveSettings()
        {
            List<Control> controls = GetTaggedControls(tabEmail);
            Settings settings = new Settings();
            foreach (Control c in controls)
            {
                settings.Add((String)c.Tag, c.Text);
            }
            Settings.Save(settings);

        }

        private void LoadSettings()
        {
            List<Control> controls = GetTaggedControls(tabEmail);
            Settings settings = Settings.Load();
            if (settings != null)
            {
                foreach (Control c in controls)
                {

                    String key = (String)c.Tag;
                    if (settings.ContainsKey(key))
                    {
                        String value;
                        if (settings.TryGetValue(key, out value))
                        {
                            c.Text = value;
                        }
                    }
                }
            }
        }

        private List<Control> GetTaggedControls(Control parent)
        {
            List<Control> controls = new List<Control>();
            foreach (Control c in parent.Controls)
            {
                if (c.Tag != null) controls.Add(c);
                controls.AddRange(GetTaggedControls(c));
            }
            return controls;
        }

        private void btnSend_Click(object sender, EventArgs e)
        {
            // check form data
            try
            {
                CheckText(tbAccount, "Kindle account");
                CheckText(tbEmail, "Your email");
                CheckText(tbSMTP, "SMTP server");
                CheckText(tbPort, "Port");
                CheckInt(tbPort, "Port");
                
                SendFile();

            }
            catch { }
            
        }

        private void SendFile()
        {
            SendArg arg = new SendArg(fileName, content, tbAccount.Text, tbEmail.Text,
                tbSMTP.Text, Int16.Parse(tbPort.Text), tbUser.Text, tbPassword.Text);

            SendForm frm = new SendForm(arg);
            frm.ShowDialog();
        }

        private void CheckText(TextBox tb, String name)
        {
            if (tb.Text == "")
            {
                MessageBox.Show(name + ": value must not be empty");
                throw new Exception();
            }
        }

        private void CheckInt(TextBox tb, String name)
        {
            try
            {
                Int16.Parse(tb.Text);
            }
            catch
            {
                MessageBox.Show(name + ": value must be integer");
                throw new Exception();
            }
        }

        private void cbFilter_SelectedIndexChanged(object sender, EventArgs e)
        {
            if (Loaded) LoadFile();
        }


    }
}
