using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Data;
using System.ComponentModel;

namespace FreeSpamerPro
{
    public class Project : INotifyPropertyChanged
    {
        int id = 0;
        string message;
        string title;
        string attachment;

        public string Attachment
        {
            get { return attachment; }
            set { attachment = value; NotifyPropertyChanged("Attachment"); }
        }

        public string Title
        {
            get { return title; }
            set { title = value; NotifyPropertyChanged("Title"); }
        }
        public string Message
        {
            get { return message; }
            set { message = value; NotifyPropertyChanged("Message");  }
        }

        public int Id
        {
            get { return id; }
            set { id = value; NotifyPropertyChanged("Id"); }
        }

        public event PropertyChangedEventHandler PropertyChanged;
        private void NotifyPropertyChanged(String info)
        {
            if (PropertyChanged != null)
            {
                PropertyChanged(this, new PropertyChangedEventArgs(info));
            }
        }

        public Project(){}

        public Project(DataRow row)
        {
            id = Int16.Parse(row["ID"].ToString());
            title = (String)row["Title"];
            message = (String)row["Message"];
            if (!row["Attachment"].Equals(DBNull.Value))
            {
                attachment = (String)row["Attachment"];
            }
        }

        /// <summary>
        /// Stores the Project into database. Returns true if the project is new.
        /// </summary>
        /// <param name="db"></param>
        /// <returns></returns>
        public bool Store(SQLiteDatabase db)
        {
            // make the texts safe
            String t = Title.Replace("'", "''");
            String m = Message.Replace("'", "''");
            String a = Attachment == null ? "" : Attachment.Replace("'", "''");

            if (id == 0)
            {
                // insert
                String sql = "INSERT INTO Project (Title, Message, Attachment) VALUES ('" + t + "', '" + m + "', '" + a + "'); SELECT last_insert_rowid()";
                Id = Int16.Parse(db.ExecuteScalar(sql));
                return true;
            }
            else
            {
                // update
                String sql = "UPDATE Project SET Title='" + t + "', Message='" + m + "', Attachment='" + a + "' WHERE ID=" + Id;
                db.ExecuteNonQuery(sql);
                return false;
            }
        }

        public void Delete(SQLiteDatabase db)
        {
            // delete users
            db.ExecuteNonQuery("DELETE FROM ProjectUser WHERE ProjectID=" + Id);
            // delete project
            db.ExecuteNonQuery("DELETE FROM Project WHERE ID=" + Id);
        }
    }
}
