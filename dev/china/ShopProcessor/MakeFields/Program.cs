using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.IO;

using ShopProcessor.CSV;

namespace MakeFields
{
    class Program
    {
        static void Main(string[] args)
        {
            FieldList list = FieldList.GetFields();

            StringBuilder sb = new StringBuilder();

            foreach (Field f in list)
            {
                sb.Append("fields.Add(new Field(");

                // title
                String title = f.Title;
                sb.Append('"');
                sb.Append(title);
                sb.Append("\", ");

                String id = '"' + Guid.NewGuid().ToString() + '"';
                switch (title)
                {
                    case "Артикул":
                        id = "Field.Article";
                        break;
                    case "Наименование (English)":
                        id = "Field.NameEn";
                        break;
                    default:
                        //
                        break;
                }

                // id
                sb.Append(id);
                sb.Append(", ");

                // quote
                sb.Append(f.Quote ? "true" : "false");
                sb.Append(", ");

                // default
                sb.Append(f.Default == null ? "null" : '"' + f.Default + '"');

                sb.AppendLine("));");
            }

            TextWriter tw = new StreamWriter("fields.txt");
            tw.Write(sb.ToString());
            tw.Close();

        }
    }
}
