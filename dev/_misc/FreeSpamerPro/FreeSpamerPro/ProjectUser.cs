using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.ComponentModel;
using System.Data;

namespace FreeSpamerPro
{
    class ProjectUser : INotifyPropertyChanged
    {
        int id = 0;
        int projectId;
        bool notified;
        String login;


        public int Id
        {
            get { return id; }
            set { id = value; NotifyPropertyChanged("Id"); }
        }
        public String Login
        {
            get { return login; }
            set { login = value; NotifyPropertyChanged("Login"); NotifyPropertyChanged("Info"); }
        }
        public bool Notified
        {
            get { return notified; }
            set { notified = value; NotifyPropertyChanged("Notified"); NotifyPropertyChanged("Info"); }
        }

        public int ProjectId
        {
            get { return projectId; }
            set { projectId = value; NotifyPropertyChanged("ProjectId"); }
        }

        public String Info
        {
            get { return login + (notified ? " (notified)" : ""); }
        }


        public event PropertyChangedEventHandler PropertyChanged;
        private void NotifyPropertyChanged(String info)
        {
            if (PropertyChanged != null)
            {
                PropertyChanged(this, new PropertyChangedEventArgs(info));
            }
        }

        public ProjectUser() { }

        public ProjectUser(DataRow row)
        {
            Id = Int16.Parse(row["ID"].ToString());
            ProjectId = Int16.Parse(row["ProjectID"].ToString());
            notified = ((int)row["Notified"]) == 1;
            Login = (String)row["Login"];
        }

        public void Insert(SQLiteDatabase db)
        {
            if (Id != 0)
            {
                throw new Exception("Already inserted");
            }
            String sql = "INSERT INTO ProjectUser (ProjectID, Login, Notified) VALUES ('" + ProjectId + "', '" + Login + "', 0); SELECT last_insert_rowid()";
            Id = Int16.Parse(db.ExecuteScalar(sql));
        }

        public void ChangeNotificationStatus(SQLiteDatabase db)
        {
            int n = Notified ? 1 : 0;
            String sql = "UPDATE ProjectUser SET Notified=" + n + " where ID=" + Id;
            db.ExecuteNonQuery(sql);
        }
    }
}
