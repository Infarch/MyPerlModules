using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Windows.Forms;

namespace BAKi
{
    public class Category : Member
    {

        public Category()
        {
            // does nothing, just for serializer
        }

        public Category(String name, String url, bool isTop)
        {
            MemberType = isTop ? Type.TopCategory : Type.SubCategory;
            Name = name;
            Url = url;
        }

        public override void Process(HtmlDocument doc)
        {
            Processed = true;

            if (MemberType == Type.TopCategory)
            {
                // get level 0 links
                foreach (HtmlElement el in doc.GetElementsByTagName("a"))
                {
                    if (el.GetAttribute("className") == "cat_t_linkto")
                    {
                        String name = el.InnerText;
                        String url = el.GetAttribute("href");
                        Children.Add(new Category(name, url, false));


                        // DEBUG!!!
                        break;

                    }
                }
            }
            else
            {
                // check sub categories

                HtmlElement div = null;
                foreach (HtmlElement x in doc.GetElementsByTagName("div"))
                {
                    if (x.GetAttribute("className") == "choose_subcategory")
                    {
                        div = x;
                        break;
                    }
                }

                if (div != null)
                {

                    int c = 0;

                    // process sub categories
                    foreach (HtmlElement a in div.GetElementsByTagName("a"))
                    {
                        String url = a.GetAttribute("href");
                        HtmlElementCollection nc = a.GetElementsByTagName("div");
                        String name = nc[0].InnerText;

                        // DEBUG!!!
                        if (c++ == 1)
                        {
                            Children.Add(new Category(name, url, false));
                            break;
                        }
                        
                    }
                }
                else
                {
                    // process products
                    foreach (HtmlElement pd in doc.GetElementsByTagName("div"))
                    {
                        if (pd.GetAttribute("className") == "cop_title")
                        {
                            HtmlElement a = pd.GetElementsByTagName("a")[0];
                            String name = a.InnerText;
                            String url = a.GetAttribute("href");
                            Children.Add(new Leaf(name, url));

                            // DEBUG!!!
                            break;
                        }
                    }


                    // DEBUG!!!
                    //return;


                    // process paginator
                    HtmlElement paginator = doc.GetElementById("paginator1");
                    
                    bool checkNext = false;

                    foreach (HtmlElement span in paginator.GetElementsByTagName("span"))
                    {
                        if (span.FirstChild.TagName.ToLower() == "strong")
                        {
                            checkNext = true;
                        }
                        else if (span.FirstChild.TagName.ToLower() == "a")
                        {
                            if (checkNext)
                            {
                                Processed = false;
                                Url = (new Uri(new Uri(Url), span.FirstChild.GetAttribute("href"))).ToString();
                                break;
                            }
                        }
                        else
                        {
                            throw new Exception("wwww");
                        }
                    }

                }

            }

            

        }
    }
}
