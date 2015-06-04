using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Data;
using System.ComponentModel;

namespace FreeSpamerPro
{
    class ProjectList : BindingList<Project>
    {
        public void Populate(SQLiteDatabase db)
        {
            String sql = "select * from [Project]";
            DataTable tb = db.GetDataTable(sql);
            foreach (DataRow row in tb.Rows)
            {
                Add(new Project(row));
            }
        }
    }
}
