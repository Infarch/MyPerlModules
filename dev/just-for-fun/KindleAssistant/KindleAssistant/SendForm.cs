﻿using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.Text;
using System.Windows.Forms;
using System.IO;
using System.Net.Mail;
using System.Net;
using System.Text.RegularExpressions;

namespace KindleAssistant
{
    public partial class SendForm : Form
    {

        private SendArg arg;

        public SendForm(SendArg arg)
            : this()
        {
            this.arg = arg;
        }

        private SendForm()
        {
            InitializeComponent();
        }

        private void SendForm_Load(object sender, EventArgs e)
        {
            lblTo.Text = arg.Account;
            String name = Path.GetFileNameWithoutExtension(arg.FileName);
            String ext = Path.GetExtension(arg.FileName);
            tbName.Text = name;
            lblExt.Text = ext;
        }

        private void btnSend_Click(object sender, EventArgs e)
        {
            String newName = tbName.Text;
            if (newName == "")
            {
                MessageBox.Show("Name must not be empty", "Error");
                return;
            }

            arg.FileName = newName + lblExt.Text;

            btnSend.Enabled = false;
            progress.Visible = true;

            sendWorker.RunWorkerAsync(arg);
        }

        /// <summary>
        /// Deprecated. Creates an attachment using plain text, without any compression.
        /// </summary>
        /// <param name="sa"></param>
        /// <returns></returns>
        private Attachment GetStringAttachment(SendArg sa)
        {
            String attachment = GetAttachment(sa);
            MemoryStream ms = new MemoryStream(Encoding.UTF8.GetBytes(attachment));
            Attachment att = new Attachment(ms, sa.FileName);
            att.NameEncoding = Encoding.Default;
            return att;
        }

        private Attachment MakeAttachment(SendArg sa)
        {
            String attachment = GetAttachment(sa);
            Stream s = ZipHelper.MakeZipStream(attachment, sa.FileName);
            return new Attachment(s, "attachment.zip", System.Net.Mime.MediaTypeNames.Application.Zip);
        }

        private String GetAttachment(SendArg sa)
        {
            String file = sa.Content;
            // check extension
            String ext = Path.GetExtension(sa.FileName).ToLower();
            if (ext == ".htm" || ext == ".html")
            {
                // modyfy the header of the file
                file = Regex.Replace(file, "<html[^>]*>.*<body[^>]*>", "<html><head><meta http-equiv=\"Content-Type\" content=\"text/html; charset=utf-8\" /></head><body>", RegexOptions.IgnoreCase | RegexOptions.Singleline);
            }

            return file;
        }

        private void btnCancel_Click(object sender, EventArgs e)
        {
            //smtpclient.SendAsyncCancel();
            sendWorker.CancelAsync();
        }

        private void sendWorker_DoWork(object sender, DoWorkEventArgs e)
        {

            SendArg sa = (SendArg)e.Argument;

            SmtpClient smtpclient = new SmtpClient(sa.Smtp, sa.Port);
            if (sa.HasSecurityCredentials())
            {
                smtpclient.Credentials = new NetworkCredential(sa.UserName, sa.Password);
            }

            MailMessage mail = new MailMessage();

            mail.From = new MailAddress(sa.From);
            mail.To.Add(sa.Account);
            mail.Subject = "Kindle assistant's message";
            mail.Body = "This message was generated by the Kindle Assistant application.";

            //Attachment att = GetSystemZipAttachment(sa);
            Attachment att = MakeAttachment(sa);






            mail.Attachments.Add(att);

            smtpclient.Send(mail);
            smtpclient.Dispose();

            att.Dispose();
        }

        private void sendWorker_RunWorkerCompleted(object sender, RunWorkerCompletedEventArgs e)
        {
            progress.Visible = false;
            if (e.Error != null)
            {
                MessageBox.Show(e.Error.Message, "Error");
            }
            else
            {
                MessageBox.Show("Sent");
            }
            this.DialogResult = DialogResult.OK;
        }

    }
}