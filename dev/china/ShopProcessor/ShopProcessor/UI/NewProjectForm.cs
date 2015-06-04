using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.Linq;
using System.Text;
using System.Windows.Forms;

using ShopProcessor.CSV;
using ShopProcessor.UI;

namespace ShopProcessor
{
    public partial class NewProjectForm : Form
    {
        private ContextMenuStrip contextMenu;
        private int selected_index;

        public String ProjectName;
        public List<String> FieldIDs = new List<string>();

        private Project project;
        private Dictionary<String, Boolean> active_fields = new Dictionary<string, bool>();
        
        public NewProjectForm()
        {
            InitializeComponent();
            contextMenu = new ContextMenuStrip();
            //contextMenu.ShowCheckMargin = false;
            contextMenu.ShowImageMargin = false;
            
            //ToolStripItem item = contextMenu.Items.Add("Edit...");
            //item.Click+=new EventHandler(item_Click);


            contextMenu.Items.Add("Edit...", null, new System.EventHandler(item_Edit));
            contextMenu.Items.Add("Delete", null, new System.EventHandler(item_Delete));
        }

        void item_Delete(object sender, EventArgs e)
        {
            if (MessageBox.Show("Do you really want to delete the field?", "Confirm", MessageBoxButtons.YesNo) == DialogResult.Yes)
            {
                Field f = (Field)checkedFields.Items[selected_index];
                checkedFields.Items.RemoveAt(selected_index);
                FieldList.RemoveCustomField(f);
                FieldList.SaveCustomFields();
            }
        }

        void item_Edit(object sender, EventArgs e)
        {
            Field f = (Field)checkedFields.Items[selected_index];
            Boolean active = checkedFields.GetItemChecked(selected_index);

            // show the field editor form
            EditFieldForm frm = new EditFieldForm(f, active);
            if (frm.ShowDialog() == DialogResult.OK)
            {
                checkedFields.SetItemChecked(selected_index, frm.GetActive());
                checkedFields.Refresh();
                FieldList.SaveCustomFields();
            }
        }

        void contextMenu_EditClicked(object sender, ToolStripItemClickedEventArgs e)
        {
            Field f = (Field)checkedFields.Items[selected_index];
            Boolean active = checkedFields.GetItemChecked(selected_index);

            // show the field editor form
            EditFieldForm frm = new EditFieldForm(f, active);
            if (frm.ShowDialog() == DialogResult.OK)
            {
                checkedFields.SetItemChecked(selected_index, frm.GetActive());
                checkedFields.Refresh();
                /*
                Field f = frm.GetField();
                FieldList.AddCustomField(f);
                checkedFields.Items.Add(f, frm.GetActive());
                */
                FieldList.SaveCustomFields();
            }
        }

        public NewProjectForm(Project p)
            : this()
        {
            this.Text = "Edit project";
            project = p;
            tbProjectName.Text = p.Title;
            foreach (String id in project.FieldIDs)
                active_fields.Add(id, true);
        }

        private void btnOk_Click(object sender, EventArgs e)
        {
            if (project != null)
            {
                project.Title = tbProjectName.Text;
                foreach (Object obj in checkedFields.CheckedItems)
                {
                    Field f = obj as Field;
                    FieldIDs.Add(f.ID);
                }
                project.FieldIDs = FieldIDs;
            }
            else
            {
                ProjectName = tbProjectName.Text;

                foreach (Object obj in checkedFields.CheckedItems)
                {
                    Field f = obj as Field;
                    FieldIDs.Add(f.ID);
                }

            }

            this.DialogResult = DialogResult.OK;
        }

        private void NewProjectForm_Load(object sender, EventArgs e)
        {
            foreach (Field f in FieldList.GetFields())
            {
                String id = f.ID;
                if (!f.Hidden)
                {
                    bool selected =
                        project == null ? f.VisibleByDefault :
                            active_fields.ContainsKey(id);
 
                    checkedFields.Items.Add(f, selected);
                }
            }
        }

        private void checkBox1_CheckedChanged(object sender, EventArgs e)
        {
            CheckBox cb = sender as CheckBox;
            CheckState state = cb.Checked ? CheckState.Checked : CheckState.Unchecked;
            for (int i = 0; i < checkedFields.Items.Count; i++)
            {
                checkedFields.SetItemCheckState(i, state);
            }
        }

        private void btnNewField_Click(object sender, EventArgs e)
        {
            // show the field editor form
            EditFieldForm frm = new EditFieldForm();
            if (frm.ShowDialog() == DialogResult.OK)
            {
                Field f = frm.GetField();
                FieldList.AddCustomField(f);
                checkedFields.Items.Add(f, frm.GetActive());
                FieldList.SaveCustomFields();
            }

        }

        private void checkedFields_MouseDown(object sender, MouseEventArgs e)
        {
            if (e.Button == MouseButtons.Right)
            {
                //select the item under the mouse pointer
                selected_index = checkedFields.IndexFromPoint(e.Location);
                if (selected_index != -1)
                {
                    Field f = (Field)checkedFields.Items[selected_index];
                    if(f.Custom)
                        contextMenu.Show(checkedFields, e.Location);
                }
            }
        }

    }
}
