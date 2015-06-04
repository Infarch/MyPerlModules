using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.Linq;
using System.Text;
using System.Windows.Forms;
using System.Text.RegularExpressions;


namespace CSharp
{
    public partial class ClassEditor : Form
    {
        ModelContext context;
        Class cls;
        bool editmode;

        public ClassEditor(ModelContext context)
        {
            InitializeComponent();
            this.context = context;
        }

        public ClassEditor(ModelContext context, Class cls)
            : this(context)
        {
            this.cls = cls;
            editmode = true;
        }

        private void btnCancel_Click(object sender, EventArgs e)
        {
            this.DialogResult = DialogResult.Cancel;
        }

        private void frmClassEditor_Load(object sender, EventArgs e)
        {
            int selfId = 0;
            if (editmode) {
                selfId=cls.Id;
            }
            else
            {
                cls = new Class();
            }

            tbClassName.Text = cls.Name;
            tbClassAlias.Text = cls.Alias;
            tbClassComment.Text = cls.Comment;

            cbClassAccessModifier.DataSource = context.AccessModifierSet;
            cbClassAccessModifier.DisplayMember = "Name";

            cbClassAncestor.DataSource = context.ClassSet.Where(x=>x.Id!=selfId);
            cbClassAncestor.DisplayMember = "Name";

        }

        private void btnOk_Click(object sender, EventArgs e)
        {
            if (ValidateForm())
            {
                cls.Name = tbClassName.Text;
                cls.Alias = tbClassAlias.Text;
                cls.Comment = tbClassComment.Text;
                cls.AccessModifier = (AccessModifier)cbClassAccessModifier.SelectedValue;
                cls.Ancestor = (Class)cbClassAncestor.SelectedValue;

                if (!editmode)
                {
                    context.ClassSet.AddObject(cls);
                }

                context.SaveChanges();

                this.DialogResult = DialogResult.OK;
            }
        }

        private bool ValidateForm()
        {
            if (String.IsNullOrEmpty(tbClassName.Text) || Regex.IsMatch(tbClassName.Text, "[^0-9a-zA-Z.]"))
            {
                MarkInvalid(tbClassName, "The name must not be empty and must consist of digits, letters and dots");
                return false;
            }
            else if(context.ClassSet.Count(x=>x.Name==tbClassName.Text) > 0)
            {
                MarkInvalid(tbClassName, "A class with the same name already exists");
                return false;
            }
            else if (!Regex.IsMatch(tbClassName.Text, "\\."))
            {
                MarkInvalid(tbClassName, "You have to specify at least one namespace");
                return false;
            }
            else
            {
                MarkValid(tbClassName);
            }

            if (Regex.IsMatch(tbClassAlias.Text, "[^0-9a-zA-Z]"))
            {
                MarkInvalid(tbClassAlias, "The alias must consist of digits and letters");
                return false;
            }
            else if (!String.IsNullOrEmpty(tbClassAlias.Text) && context.ClassSet.Count(x => x.Alias == tbClassAlias.Text) > 0)
            {
                MarkInvalid(tbClassAlias, "A class with the same alias already exists");
                return false;
            }
            else
            {
                MarkValid(tbClassAlias);
            }


            return true;
        }

        private void MarkValid(Control c)
        {
            errorProvider.SetError(c, String.Empty);
        }

        private void MarkInvalid(Control c, string p)
        {
            errorProvider.SetIconAlignment(c, ErrorIconAlignment.MiddleRight);
            errorProvider.SetIconPadding(c, 2);
            errorProvider.SetError(c, p);
        }
    }
}
