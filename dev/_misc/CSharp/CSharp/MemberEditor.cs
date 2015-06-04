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
    public partial class MemberEditor : Form
    {
        ModelContext context;
        Class cls;

        public MemberEditor(ModelContext context, Class cls)
        {
            InitializeComponent();
            this.context = context;
            this.cls = cls;
        }

        private void btnCancel_Click(object sender, EventArgs e)
        {
            this.DialogResult = DialogResult.Cancel;
        }

        private void btnOk_Click(object sender, EventArgs e)
        {
            if (ValidateForm())
            {

                MemberType mt = new MemberType();
                mt.Class = (Class)cbMemberType.SelectedValue;
                context.MemberTypeSet.AddObject(mt);

                Member m = new Member();
                m.Name = tbClassMemberName.Text;
                m.AccessModifier = (AccessModifier)cbMemberAccessModifier.SelectedValue;
                m.MemberType = mt;
                m.Class = cls;
                context.MemberSet.AddObject(m);
                
                context.SaveChanges();

                this.DialogResult = DialogResult.OK;
            }
        }

        private bool ValidateForm()
        {
            if (String.IsNullOrEmpty(tbClassMemberName.Text) || Regex.IsMatch(tbClassMemberName.Text, "[^0-9a-zA-Z]"))
            {
                MarkInvalid(tbClassMemberName, "The name must not be empty and must consist of digits and letters");
                return false;
            }
            else if (cls.Members.Count(x => x.Name == tbClassMemberName.Text) > 0)
            {
                MarkInvalid(tbClassMemberName, "A member with the same name already exists");
                return false;
            }
            else
            {
                MarkValid(tbClassMemberName);
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

        private void MemberEditor_Load(object sender, EventArgs e)
        {
            cbMemberAccessModifier.DataSource = context.AccessModifierSet;
            cbMemberAccessModifier.DisplayMember = "Name";

            cbMemberType.DataSource = context.ClassSet;
            cbMemberType.DisplayMember = "Name";
        }

    }
}
