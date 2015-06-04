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
    public partial class MethodEditor : Form
    {
        ModelContext context;
        Class cls;

        BindingList<Parameter> listParams = new BindingList<Parameter>();

        public MethodEditor(ModelContext context, Class cls)
        {
            this.context = context;
            this.cls = cls;
            InitializeComponent();
        }

        private void rbVoid_CheckedChanged(object sender, EventArgs e)
        {
            cbMethodType.Enabled = !rbVoid.Checked;
        }

        private void MethodEditor_Load(object sender, EventArgs e)
        {
            cbMethodAccessModifier.DataSource = context.AccessModifierSet;
            cbMethodAccessModifier.DisplayMember = "Name";

            cbMethodType.DataSource = context.ClassSet.Where(x => x.Id > 0);
            cbMethodType.DisplayMember = "Name";

            lbParameters.DataSource = listParams;
            lbParameters.DisplayMember = "Name";

            cbMethodParamType.DataSource = context.ClassSet.Where(x => x.Id > 0);
            cbMethodParamType.DisplayMember = "Name";
        }

        private void btnCancel_Click(object sender, EventArgs e)
        {
            this.DialogResult = DialogResult.Cancel;
        }

        private void btnOk_Click(object sender, EventArgs e)
        {

            if (ValidateForm())
            {

                Method method = new Method();
                method.Name = tbMethodName.Text;
                method.Comment = tbMethodComment.Text;
                method.AccessModifier = (AccessModifier)cbMethodAccessModifier.SelectedValue;
                method.Class = cls;

                if (rbTyped.Checked)
                {
                    ReturnType rt = new ReturnType();
                    rt.Class = (Class)cbMethodType.SelectedValue;
                    method.ReturnType = rt;
                    context.ReturnTypeSet.AddObject(rt);
                }

                byte order = 0;
                foreach (Parameter p in listParams)
                {
                    p.OrderNmber = order++;
                    method.Parameters.Add(p);
                }

                context.MethodSet.AddObject(method);
                context.SaveChanges();

                this.DialogResult = DialogResult.OK;

            }
        }

        private bool ValidateForm()
        {
            if (String.IsNullOrEmpty(tbMethodName.Text) || Regex.IsMatch(tbMethodName.Text, "[^0-9a-zA-Z]"))
            {
                MarkInvalid(tbMethodName, "The name must not be empty and must consist of digits and letters");
                return false;
            }
            else if (cls.Methods.Count(x => x.Name == tbMethodName.Text) > 0)
            {
                MarkInvalid(tbMethodName, "A method with the same name already exists");
                return false;
            }
            else
            {
                MarkValid(tbMethodName);
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

        private void btnAddMethodParam_Click(object sender, EventArgs e)
        {
            if (ValidateParam())
            {
                Parameter param = new Parameter()
                {
                    Name = tbMethodParamName.Text,
                    Type=(Class)cbMethodParamType.SelectedValue
                };
                listParams.Add(param);

                cbMethodParamType.SelectedIndex = 0;
                tbMethodParamName.Text = String.Empty;
            }
        }

        private bool ValidateParam()
        {
            if (String.IsNullOrEmpty(tbMethodParamName.Text) || Regex.IsMatch(tbMethodParamName.Text, "[^0-9a-zA-Z]"))
            {
                MarkInvalid(gbParam, "The name must not be empty and must consist of digits and letters");
                return false;
            }
            else if (listParams.Any(x => x.Name == tbMethodParamName.Text))
            {
                MarkInvalid(gbParam, "A parameter with the same name already exists");
                return false;
            }
            else
            {
                MarkValid(gbParam);
            }

            return true;
        }

    }
}
