using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Windows.Forms;
using FormHelper;

namespace FreeSpamerPro
{
    public partial class Form1
    {

        /// <summary>
        /// Schedule some interval before processing page
        /// </summary>
        /// <param name="sec"></param>
        /// <param name="tick"></param>
        private void SetInterval(int sec, WebTick tick)
        {
            // add a MANDATORY pause
            for (int k = sec; k < 3; k++)
            {
                tlist.Enqueue(new WaitTick());
            }
            for (int i = 0; i < sec; i++)
            {
                WaitTick t = new WaitTick();
                t.Tag = String.Format("Wait {0} second(s)", sec - i);
                tlist.Enqueue(t);
            }
            tlist.Enqueue(tick);
        }
        
        /// <summary>
        /// Called when the browser has finished creating document,
        /// switches the software to an appropriate working mode
        /// </summary>
        private void SelectBrowserHandler()
        {
            switch (mode)
            {
                case ParseMode.Ready:
                    // do nothing
                    break;
                case ParseMode.TakePeople:
                    SetInterval(parsingPause, new WebTick(new Action(TakePeople)));
                    break;
                case ParseMode.OpenPostBox:
                    int rnd = cbRandom.Checked ? random.Next(1, 30) : 0;
                    SetInterval(messagePause + rnd, new WebTick(new Action(SendMessage)));
                    break;
                case ParseMode.SendMessage:
                    SetInterval(parsingPause, new WebTick(new Action(MessageSent)));
                    break;
            }
        }

        /// <summary>
        ///  A message has been sent, go to process another user
        /// </summary>
        private void MessageSent()
        {
            stText.Text = "Message sent to " + currentUser.Login;
            
            // update progress
            stProgress.Increment(1);

            // next iteration
            OpenPostBox();
        }

        /// <summary>
        /// Populates web form and then sends it
        /// </summary>
        private void SendMessage()
        {
            stText.Text = "Sending message";

            // convert a message from unicode to cp1251
            Encoding te = Encoding.GetEncoding("windows-1251");
            Encoding se = Encoding.Unicode;

            byte[] sourceBytes = se.GetBytes(activeProject.Message);
            byte[] destBytes = Encoding.Convert(se, te, sourceBytes);

            char[] destChars = new char[te.GetCharCount(destBytes, 0, destBytes.Length)];
            te.GetChars(destBytes, 0, destBytes.Length, destChars, 0);
            String msg = new String(destChars);

            // set message text
            HtmlElement box = browser.Document.GetElementById("msg");
            box.InnerText = msg;

            HtmlElement form = null;
            for (int i = 0; i < browser.Document.Forms.Count; i++)
            {
                if (browser.Document.Forms[i].GetAttribute("enctype").ToLower() == "multipart/form-data")
                {
                    form = browser.Document.Forms[i];
                    break;
                }
            }
            FormToMultipartPostData postData = new FormToMultipartPostData(browser, form);
            // process attachment
            if (attach != null && !attach.Equals(String.Empty))
            {
                Log("Going to send " + attach);
                postData.SetFile("attach[]", attach);
            }
            mode = ParseMode.SendMessage;
            stText.Text = "Submit data";

            currentUser.Notified = true;
            currentUser.ChangeNotificationStatus(new SQLiteDatabase());

            // emulate sending for debug purposes
            //browser.Navigate("http://free-lance.ru");

            // send real message
            postData.Submit();
        }

        /// <summary>
        ///  Collect users from the current page in browser
        /// </summary>
        private void TakePeople()
        {
            stText.Text = "Reading users";

            SQLiteDatabase db = new SQLiteDatabase();
            // take people
            HtmlElementCollection tdlist = browser.Document.GetElementsByTagName("td");
            foreach (HtmlElement td in tdlist)
            {
                if (td.GetAttribute("className").Equals("cf-user"))
                {
                    // there is a user login in the first image
                    HtmlElement img = td.GetElementsByTagName("img")[0];
                    String login = img.GetAttribute("alt");
                    bool found = false;
                    try
                    {
                        users.First(user => user.Login.Equals(login));
                        found = true;
                    }
                    catch { }
                    if (!found)
                    {
                        ProjectUser user = new ProjectUser();
                        user.ProjectId = activeProject.Id;
                        user.Login = login;
                        // insert into db
                        user.Insert(db);
                        // add to list
                        users.Add(user);
                    }
                }
            }

            // check 'Next page'
            HtmlElement a = browser.Document.GetElementById("PrevLink");
            if (a != null)
            {
                a.InvokeMember("Click");
                return;
            }

            // No more users
            ResetParser();
            MessageBox.Show("Done");

        }

        /// <summary>
        /// Timer handler
        /// </summary>
        private void ProcessTimer()
        {
            ParseTick t = null;
            if (tlist.TryPeek(out t))
            {
                if (t.Tag != null) stText.Text = t.Tag;
                if (t.DoWork() == TickResult.Ok)
                {
                    // remove it from the queue
                    tlist.TryDequeue(out t);
                }
                else
                {
                    stText.Text = "Try internet connection";
                }
            }
        }

        /// <summary>
        /// The first step in sending message operation
        /// </summary>
        void OpenPostBox()
        {
            bool found = false;
            try
            {
                currentUser = users.First(user => user.Notified == false);
                found = true;
            }
            catch { }
            if (found)
            {
                stText.Text = "Opening " + currentUser.Login;

                mode = ParseMode.OpenPostBox;

                int left = users.Count(x => x.Notified == false);
                int estimate = Convert.ToInt32((parsingPause + messagePause + 5) * left / 60);
                stEstimate.Text = "Estimated time: " + estimate + " min";

                // TODO real mode!!!
                browser.Navigate("http://www.free-lance.ru/contacts/?from=" + currentUser.Login);

                // TODO demo mode!!!
                //browser.Navigate("http://www.free-lance.ru/contacts/?from=" + "infarch");

            }
            else
            {
                ResetParser();
                MessageBox.Show("Notification sent to all users");
            }

        }

        /// <summary>
        /// Makes the parser ready for other actions
        /// </summary>
        private void ResetParser()
        {
            parseTimer.Stop();
            mode = ParseMode.Ready;
            stText.Text = "Ready";
            stEstimate.Text = "";
            btnPause.Text = "Pause";
            stProgress.Visible = false;
            btnTakeUsers.Enabled = true;
            btnSendMessage.Enabled = true;
            btnPause.Enabled = false;
            btnStop.Enabled = false;
        }



    }
}
