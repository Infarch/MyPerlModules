using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace ShopProcessor.CSV
{
    public class CSVProcessor
    {
        public static void MakeHeader(FieldList fields, StringBuilder sb)
        {

            for (int i = 0; i < fields.Count; i++)
            {
                Field f = fields[i];
                f.RenderTo(sb, f.Title, ";");
                if ((i + 1) < fields.Count)
                {
                    sb.Append(";");
                }
            }
            sb.AppendLine("");
        }

        public static void AddRow(FieldList fields, StringBuilder sb, Dictionary<String, String> dic)
        {

            for (int i = 0; i < fields.Count; i++)
            {
                Field f = fields[i];
                f.AppendValueTo(sb, dic);
                if ((i + 1) < fields.Count)
                {
                    sb.Append(";");
                }
            }
            sb.AppendLine("");
        }

    }
}
