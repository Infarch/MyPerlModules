using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.Linq;
using System.Text;
using System.Windows.Forms;
using ShopProcessor.CSV;

namespace ShopProcessor.UI
{
    public partial class EditFieldForm : Form
    {
        private Field field;
        private Boolean active;
        private bool isEdit = false;

        public Field GetField()
        {
            return field;
        }

        public Boolean GetActive()
        {
            return active;
        }


        public EditFieldForm()
        {
            InitializeComponent();
        }

        public EditFieldForm(Field f, Boolean isActive)
            : this()
        {
            field = f;
            active = isActive;
            isEdit = true;
        }

        private void EditFieldForm_Load(object sender, EventArgs e)
        {
            if (field == null)
            {
                String name = "Field " + FieldList.GetFields().Count;
                String id = Guid.NewGuid().ToString();
                field = new Field(name, id, true);
                this.Text = "New field";
            }
            else
            {
                this.Text = "Edit field";
            }

            tbFieldName.Text = field.Title;
            cbActive.Checked = active;
        }

        private void cbActive_CheckedChanged(object sender, EventArgs e)
        {
            active = ((CheckBox)sender).Checked;
        }

        private void btnOk_Click(object sender, EventArgs e)
        {
            bool ok = false;
            foreach (Field f in FieldList.GetFields())
            {
                if (f != field)
                {
                    ok = f.Title != tbFieldName.Text;
                    if (!ok)
                    {
                        MessageBox.Show("You already have a field with the same name", "Error");
                        break;
                    }
                }
            }
            if (ok)
            {
                field.Title = tbFieldName.Text;
                this.DialogResult = DialogResult.OK;

            }
        }

    }
}
