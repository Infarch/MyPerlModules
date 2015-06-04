using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Data;
using System.ComponentModel;

namespace FreeSpamerPro
{
    class ProjectUserList : BindingList<ProjectUser>
    {

        public void Populate(SQLiteDatabase db, Project p)
        {
            String sql = "select * from [ProjectUser] where ProjectID=" + p.Id;
            DataTable tb = db.GetDataTable(sql);
            foreach (DataRow row in tb.Rows)
            {
                Add(new ProjectUser(row));
            }

        }

    }
}
