using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.IO;


namespace BakiMT
{
    public class Exporter
    {

        public static void WriteToStream(Stream s, CategoryRoot root)
        {
            TextWriter tw = new StreamWriter(s, Encoding.GetEncoding("windows-1251"));


            foreach (AbstractMember m in root.Children){
                CategoryTop tc = m as CategoryTop;

                foreach (AbstractMember m1 in tc.Children)
                {
                    CategorySub sc = m1 as CategorySub;

                    foreach (AbstractMember m2 in sc.Children)
                    {
                        AppendProduct(tw, tc, sc, m2 as Product);
                    }
                }

                //List<String> catlist = new List<String>();
                //catlist.Add(tc.Name);
                //foreach (AbstractMember m1 in tc.Children)
                //{
                //    CategorySub sc = m1 as CategorySub;
                //    AppendSubDirectory(tw, sc, catlist);
                //}

            }


            tw.Close();
        }

        private static void AppendProduct(TextWriter tw, CategoryTop tc, CategorySub sc, Product product)
        {
            if (product.Unprocessed) return;
            StringBuilder sb = new StringBuilder();

            // top category
            sb.Append(Correct(tc.Name));
            sb.Append(';');
            // sub category
            sb.Append(Correct(sc.Name));
            sb.Append(';');
            // name
            sb.Append(Correct(product.Name));
            sb.Append(';');
            // address
            sb.Append(Correct(product.Address));
            sb.Append(';');
            // coords
            sb.Append(Correct(product.Coords));
            sb.Append(';');
            // phones
            sb.Append(Correct(product.Phones));
            sb.Append(';');
            // emails
            sb.Append(Correct(product.Emails));
            sb.Append(';');
            // sites
            sb.Append(Correct(String.Join(",", product.Sites)));

            tw.WriteLine(sb.ToString());

        }

        private static void AppendSubDirectory(TextWriter tw, CategorySub sc, List<String> catlist)
        {
            catlist.Add(sc.Name);
            foreach (AbstractMember m in sc.Children)
            {

                if (m is CategorySub)
                {
                    AppendSubDirectory(tw, m as CategorySub, catlist);
                }
                else
                {
                    AppendProduct(tw, m as Product, catlist);
                }

            }
        }

        private static String Correct(List<String> data)
        {
            return Correct(String.Join(",", data));
        }

        private static String Correct(String data)
        {
            return '"' + data + '"';
        }

        private static void AppendProduct(TextWriter tw, Product product, List<String> catlist)
        {
            
            if (product.Unprocessed) return;

            StringBuilder sb = new StringBuilder();
            // category
            sb.Append(Correct(String.Join(",", catlist)));
            sb.Append(';');
            // name
            sb.Append(Correct(product.Name));
            sb.Append(';');
            // address
            sb.Append(Correct(product.Address));
            sb.Append(';');
            // coords
            sb.Append(Correct(product.Coords));
            sb.Append(';');
            // phones
            sb.Append(Correct(product.Phones));
            sb.Append(';');
            // emails
            sb.Append(Correct(product.Emails));
            sb.Append(';');
            // sites
            sb.Append(Correct(product.Sites));

            tw.WriteLine(sb.ToString());

        }

    }
}
