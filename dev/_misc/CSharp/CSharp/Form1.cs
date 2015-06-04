using System;
using System.Collections.Generic;
using System.Collections;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.Linq;
using System.Text;
using System.Windows.Forms;
using System.IO;

using System.Data.Objects;
using System.Data.Objects.DataClasses;


namespace CSharp
{
    public partial class Form1 : Form
    {

        private const string ObjectClass = "System.Object";

        ModelContext context;


        public Form1()
        {
            InitializeComponent();
        }

        private void Form1_Load(object sender, EventArgs e)
        {
            // init the Context
            context = new ModelContext();

            // check existence of the database
            if (!context.DatabaseExists()) context.CreateDatabase();

            // check existence of common access modifiers, create them if so...
            var pub = new AccessModifier() { Name = "public" };
            if (context.AccessModifierSet.Count() == 0)
            {
                context.AccessModifierSet.AddObject(pub);
                context.AccessModifierSet.AddObject(new AccessModifier() { Name = "private" });
                context.AccessModifierSet.AddObject(new AccessModifier() { Name = "protected" });
                context.AccessModifierSet.AddObject(new AccessModifier() { Name = "internal" });
                
                context.SaveChanges();
            }

            // check existence of System.Object
            int count = context.ClassSet.Count(c => c.Name == ObjectClass);
            if (count > 1)
            {
                throw new Exception("Wrong database content");
            }
            else if (count == 0)
            {
                context.ClassSet.AddObject(new Class() { Name = ObjectClass, Alias = "object", AccessModifier = pub });
                context.SaveChanges();
            }

            // bind list of classes to the context
            BindClassList();
        }

        private void btnAddClass_Click(object sender, EventArgs e)
        {
            var frm = new ClassEditor(context);
            if (frm.ShowDialog() == DialogResult.OK)
            {
                // bind the list again to reflect changes in data set
                BindClassList();
                // select the last inserted class
                lbClasses.SelectedIndex = context.ClassSet.Count() - 1;
            }
        }

        private void lbClasses_SelectedIndexChanged(object sender, EventArgs e)
        {
            bool en = lbClasses.SelectedIndex != -1;
            btnExport.Enabled = en;
            btnAddClassMember.Enabled = en;
            btnAddClassMethod.Enabled = en;
            // do other stuff
            if (en)
            {
                BindClassMembers();
                BindClassMethods();
            }
            else
            {
                lbClassMembers.DataSource = null;
                lbClassMethods.DataSource = null;
            }
        }

        private void BindClassMembers()
        {
            int classId = ((Class)lbClasses.SelectedValue).Id;
            lbClassMembers.DataSource = context.MemberSet.Where(x => x.ClassId == classId);
            lbClassMembers.DisplayMember = "Name";
        }

        private void BindClassList()
        {
            lbClasses.DataSource = context.ClassSet.Where(x => x.Id > 0);
            lbClasses.DisplayMember = "Name";
        }

        private void BindClassMethods()
        {
            int classId = ((Class)lbClasses.SelectedValue).Id;
            lbClassMethods.DataSource = context.MethodSet.Where(x => x.ClassId == classId);
            lbClassMethods.DisplayMember = "Name";
        }

        private void btnExport_Click(object sender, EventArgs e)
        {
            if (exportFileDialog.ShowDialog() == DialogResult.OK)
            {
                string s = BuildClassExport((Class)lbClasses.SelectedValue);
                using (TextWriter tw = new StreamWriter(exportFileDialog.FileName))
                {
                    tw.WriteLine(s);
                }
            }
        }

        /// <summary>
        /// 
        /// </summary>
        /// <param name="cls"></param>
        /// <param name="ns"></param>
        /// <param name="name"></param>
        /// <returns></returns>
        private void ParseClassName(Class cls, out string ns, out string name)
        {
            int i = cls.Name.LastIndexOf('.');
            if (i >= 0)
            {
                ns = cls.Name.Substring(0, i);
                name = cls.Name.Substring(i + 1);
            }
            else
            {
                ns = null;
                name = cls.Name;
            }
        }

        private string BuildClassExport(Class cls)
        {
            //StringBuilder sbNs = new StringBuilder();
            StringBuilder sbMembers = new StringBuilder();
            StringBuilder sbMethods = new StringBuilder();



            HashSet<String> ns = new HashSet<String>();
            ns.Add("System");

            string hostNs = null;
            string hostClass = null;
            ParseClassName(cls, out hostNs, out hostClass);

            string ancestorName = null;
            if (cls.Ancestor != null && cls.Ancestor.Name != ObjectClass)
            {
                string ancestorNs = null;
                ParseClassName(cls.Ancestor, out ancestorNs, out ancestorName);
                ns.Add(ancestorNs);
            }


            // append members
            foreach (Member member in cls.Members)
            {
                sbMembers.Append("    ").Append(member.AccessModifier.Name).Append(' ');
                string memberTypeAlias = member.MemberType.Class.Alias;
                string memberTypeClass = null;
                string memberTypeNs = null;
                ParseClassName(member.MemberType.Class, out memberTypeNs, out memberTypeClass);
                ns.Add(memberTypeNs);
                if (String.IsNullOrEmpty(memberTypeAlias)) memberTypeAlias = memberTypeClass;
                sbMembers.Append(memberTypeAlias).Append(' ').Append(member.Name).AppendLine(";");
            }

            
            // append methods
            foreach (Method method in cls.Methods)
            {
                StringBuilder sbMethodComment = new StringBuilder();
                StringBuilder sbMethodDeclaration = new StringBuilder();

                sbMethodComment.AppendLine("    /// <summary>");
                foreach (string line in method.Comment.Split(new string[] { Environment.NewLine }, StringSplitOptions.RemoveEmptyEntries))
                {
                    sbMethodComment.Append("    /// ").AppendLine(line);
                }
                sbMethodComment.AppendLine("    /// </summary>");

                sbMethodDeclaration.Append("    ").Append(method.AccessModifier.Name).Append(' ');
                bool returns = false;
                if (method.ReturnType != null)
                {
                    returns = true;
                    string methodTypeAlias = method.ReturnType.Class.Alias;
                    string methodTypeClass = null;
                    string methodTypeNs = null;
                    ParseClassName(method.ReturnType.Class, out methodTypeNs, out methodTypeClass);
                    ns.Add(methodTypeNs);
                    if (String.IsNullOrEmpty(methodTypeAlias)) methodTypeAlias = methodTypeClass;
                    sbMethodDeclaration.Append(methodTypeAlias);
                }
                else
                {
                    sbMethodDeclaration.Append("void");
                }
                sbMethodDeclaration.Append(' ').Append(method.Name).Append('(');

                int paramCount = 0;
                foreach (Parameter param in method.Parameters)
                {
                    string paramAlias = param.Type.Alias;
                    string paramClass = null;
                    string paramNs = null;
                    ParseClassName(param.Type, out paramNs, out paramClass);
                    ns.Add(paramNs);
                    if (String.IsNullOrEmpty(paramAlias)) paramAlias = paramClass;
                    if (paramCount++ > 0) sbMethodDeclaration.Append(", ");
                    sbMethodDeclaration.Append(paramAlias).Append(' ').Append(param.Name);
                    sbMethodComment.Append("    ////<param name=\"").Append(param.Name).AppendLine("\"></param>");
                }

                sbMethodDeclaration.AppendLine(") { }").AppendLine();
                if (returns) sbMethodComment.AppendLine("    /// <returns></returns>");

                sbMethods.Append(sbMethodComment.ToString()).Append(sbMethodDeclaration.ToString());
            }




            StringBuilder output = new StringBuilder();
            foreach (string s in ns.ToArray())
            {
                output.Append("using ").Append(s).AppendLine(";");
            }
            output.AppendLine();

            output.Append("namespace ").Append(hostNs).AppendLine(" {").AppendLine();

            // start writting class
            if (!String.IsNullOrEmpty(cls.Comment))
            {
                output.AppendLine("  /// <summary>");
                foreach (string line in cls.Comment.Split(new string[]{Environment.NewLine}, StringSplitOptions.RemoveEmptyEntries))
                {
                    output.Append("  /// ").AppendLine(line);
                }
                output.AppendLine("  /// </summary>");
            }
            output.Append("  ").Append(cls.AccessModifier.Name).Append(" class ").Append(hostClass);
            if (ancestorName != null)
            {
                output.Append(" : ").Append(ancestorName);
            }
            output.AppendLine(" {").AppendLine();



            output.AppendLine(sbMembers.ToString());
            output.AppendLine(sbMethods.ToString());



            // end writting class
            output.AppendLine("  }").AppendLine().AppendLine("}");


            return output.ToString();
        }

        private void btnAddClassMember_Click(object sender, EventArgs e)
        {
            MemberEditor frm = new MemberEditor(context, (Class)lbClasses.SelectedValue);
            if (frm.ShowDialog() == DialogResult.OK) BindClassMembers();
        }

        private void btnAddClassMethod_Click(object sender, EventArgs e)
        {
            MethodEditor frm = new MethodEditor(context, (Class)lbClasses.SelectedValue);
            if (frm.ShowDialog() == DialogResult.OK) BindClassMethods();
        }
    }
}
