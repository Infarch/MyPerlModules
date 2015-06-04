using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace KindleAssistant
{
    public class SendArg
    {
        private String fileName;
        private String content;
        private String account;

        public String Account
        {
            get { return account; }
            set { account = value; }
        }
        private String from;

        public String From
        {
            get { return from; }
            set { from = value; }
        }
        private String smtp;

        public String Smtp
        {
            get { return smtp; }
            set { smtp = value; }
        }
        private Int16 port;

        public Int16 Port
        {
            get { return port; }
            set { port = value; }
        }

        private String userName;

        public String UserName
        {
            get { return userName; }
            set { userName = value; }
        }
        private String password;

        public String Password
        {
            get { return password; }
            set { password = value; }
        }


        //public Int16 Port
        //{
        //    get { return port; }
        //    set { port = value; }
        //}


        //public String Smtp
        //{
        //    get { return smtp; }
        //    set { smtp = value; }
        //}

        //public String From
        //{
        //    get { return from; }
        //    set { from = value; }
        //}

        //public String Account
        //{
        //    get { return account; }
        //    set { account = value; }
        //}

        public String Content
        {
            get { return content; }
            set { content = value; }
        }

        public String FileName
        {
            get { return fileName; }
            set { fileName = value; }
        }

        public SendArg(String fileName, String content, String account, String from, String smtp, Int16 port, String userName, String pass)
        {
            this.fileName = fileName;
            this.content = content;
            this.account = account;
            this.from = from;
            this.smtp = smtp;
            this.port = port;
            this.userName = userName;
            this.password = pass;
        }

        public bool HasSecurityCredentials()
        {
            return UserName != null && UserName != "" && Password != null && Password != "";
        }

    }
}
