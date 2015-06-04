using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Text.RegularExpressions;

namespace PicassaLib
{
    public class CSV
    {
        private class Field
        {
            private String title;
            private String Map;
            private Boolean Quote;
            private String Default;
            private Guid id;

            public Guid ID
            {
                get { return id; }
                set { id = value; }
            }

            public String Title
            {
                get { return title; }
                set { title = value; }
            }

            public Field(String title, String map, Boolean quote, String deflt)
            {
                Title = title;
                Map = map;
                Quote = quote;
                Default = deflt;

                ID = Guid.NewGuid();
            }

            public void RenderTo(StringBuilder sb, String value, String separator, Boolean quote)
            {
                if (value != null)
                {
                    if (Regex.IsMatch(value, separator, RegexOptions.IgnoreCase) || quote)
                    {
                        sb.Append("\"" + value + "\"");
                    }
                    else
                    {
                        sb.Append(value);
                    }
                }
            }

            public void RenderTo(StringBuilder sb, String value, String separator)
            {
                RenderTo(sb, value, separator, false);
            }

            public void AppendValueTo(StringBuilder sb, Dictionary<String, String> dic)
            {
                String val = null;
                dic.TryGetValue(Map, out val);
                if (val == null)
                {
                    // try default
                    if (!dic.ContainsKey("suppress_defaults"))
                    {
                        val = Default;
                    }
                }
                // do we have any value?
                if (val != null)
                {
                    RenderTo(sb, val, ";", Quote);
                }

            }
        }

        private List<Field> fields;

        public CSV()
        {
            // init fields
            fields = new List<Field>();

            fields.Add(new Field("Артикул", "code", true, null));
            fields.Add(new Field("Наименование", "name", false, null));
            fields.Add(new Field("ID страницы (часть URL; используется в ссылках на эту страницу)", "page_id", false, null));
            fields.Add(new Field("Цена", "price", false, "0.01"));
            fields.Add(new Field("Название вида налогов", "-", false, null));
            fields.Add(new Field("Скрытый", "-", false, null));
            fields.Add(new Field("Можно купить", "-", false, "1"));
            fields.Add(new Field("Старая цена", "-", false, "0"));
            fields.Add(new Field("Продано", "-", false, "0"));
            fields.Add(new Field("Описание", "description", true, null));
            fields.Add(new Field("Краткое описание", "-", false, null));
            fields.Add(new Field("Сортировка", "-", false,  "0"));
            fields.Add(new Field("Заголовок страницы", "-", false, null));
            fields.Add(new Field("Тэг META keywords", "-", false, null));
            fields.Add(new Field("Тэг META description", "-", false, null));
            fields.Add(new Field("Стоимость упаковки", "-", false,  "0"));
            fields.Add(new Field("Вес продукта", "-", false,  "0"));
            fields.Add(new Field("Бесплатная доставка", "-", false,  "0"));
            fields.Add(new Field("Ограничение на минимальный заказ продукта (штук)", "-", false, "1"));
            fields.Add(new Field("Файл продукта", "-", false, null));
            fields.Add(new Field("Количество дней для скачивания", "-", false, "5"));
            fields.Add(new Field("Количество загрузок (раз)", "-", false, "5"));

            fields.Add(new Field("Фотография", "-", true, null));
            fields.Add(new Field("Фотография", "picture_1", true, null));
            fields.Add(new Field("Фотография", "picture_2", true, null));
            fields.Add(new Field("Фотография", "picture_3", true, null));
            fields.Add(new Field("Фотография", "picture_4", true, null));
            fields.Add(new Field("Фотография", "picture_5", true, null));
            fields.Add(new Field("Фотография", "picture_6", true, null));
            fields.Add(new Field("Фотография", "picture_7", true, null));
            fields.Add(new Field("Фотография", "picture_8", true, null));
            fields.Add(new Field("Фотография", "picture_9", true, null));
            fields.Add(new Field("Фотография", "picture_10", true, null));
            fields.Add(new Field("Фотография", "picture_11", true, null));
            fields.Add(new Field("Фотография", "picture_12", true, null));
            fields.Add(new Field("Фотография", "picture_13", true, null));
            fields.Add(new Field("Фотография", "picture_14", true, null));
            fields.Add(new Field("Фотография", "picture_15", true, null));

            fields.Add(new Field("0-12 мес.", "-", false, null));
            fields.Add(new Field("0-3 лет", "-", false, null));
            fields.Add(new Field("1-11 лет", "-", false, null));
            fields.Add(new Field("1-2 лет", "-", false, null));
            fields.Add(new Field("1-6 лет", "-", false, null));
            fields.Add(new Field("1.5-6 лет", "-", false, null));
            fields.Add(new Field("2-10 лет", "-", false, null));
            fields.Add(new Field("2-14 лет", "-", false, null));
            fields.Add(new Field("2-18 мес.", "-", false, null));
            fields.Add(new Field("2-3 года", "-", false, null));
            fields.Add(new Field("2-8 лет", "-", false, null));
            fields.Add(new Field("3-13 лет", "-", false, null));
            fields.Add(new Field("3-24 мес.", "-", false, null));
            fields.Add(new Field("3-5 лет", "-", false, null));
            fields.Add(new Field("3-6 лет", "-", false, null));
            fields.Add(new Field("3мес.-3лет", "-", false, null));
            fields.Add(new Field("4-14 лет", "-", false, null));
            fields.Add(new Field("4-16 лет", "-", false, null));
            fields.Add(new Field("4-18 мес.", "-", false, null));
            fields.Add(new Field("4-6 лет", "-", false, null));
            fields.Add(new Field("4-8 лет", "-", false, null));
            fields.Add(new Field("5-15 лет", "-", false, null));
            fields.Add(new Field("5-8 мес.", "-", false, null));
            fields.Add(new Field("5-9 лет", "-", false, null));
            fields.Add(new Field("6-16 лет", "-", false, null));
            fields.Add(new Field("7-10 лет", "-", false, null));
            fields.Add(new Field("7-12 лет", "-", false, null));
            fields.Add(new Field("9-24 мес.", "-", false, null));
            fields.Add(new Field("9мес.-2 лет", "-", false, null));
            fields.Add(new Field("UK0-16", "-", false, null));
            fields.Add(new Field("Длина стопы 10,5-13,5 см", "-", false, null));
            fields.Add(new Field("Длина стопы 10.5см-13.5 см", "-", false, null));
            fields.Add(new Field("Длина стопы 11.5см-13.5 cm", "-", false, null));
            fields.Add(new Field("Длина стопы 12.5см-16.1см", "-", false, null));
            fields.Add(new Field("Длина стопы 12.8см-15.2см", "-", false, null));
            fields.Add(new Field("Длина стопы 12см-14см", "-", false, null));
            fields.Add(new Field("Длина стопы 13.4см-15.8см", "-", false, null));
            fields.Add(new Field("Длина стопы 13.4см-16.4см ", "-", false, null));
            fields.Add(new Field("Длина стопы 13.5-17см", "-", false, null));
            fields.Add(new Field("Длина стопы 14-16.5см", "-", false, null));
            fields.Add(new Field("Длина стопы 15-20см", "-", false, null));
            fields.Add(new Field("Длина стопы 15-22см", "-", false, null));
            fields.Add(new Field("Единый размер", "-", false, null));
            fields.Add(new Field("Размер", "-", false, null));
            fields.Add(new Field("Размер 0,5-2 года", "-", false, null));
            fields.Add(new Field("Размер 0,5-3 года", "-", false, null));
            fields.Add(new Field("Размер 0-3", "-", false, null));
            fields.Add(new Field("Размер 0-3 года", "-", false, null));
            fields.Add(new Field("Размер 1,5-3 года", "-", false, null));
            fields.Add(new Field("Размер 1,5-5 лет", "-", false, null));
            fields.Add(new Field("Размер 1,5-6 лет", "-", false, null));
            fields.Add(new Field("Размер 1,5-7 лет", "-", false, null));
            fields.Add(new Field("Размер 1-12 лет", "-", false, null));
            fields.Add(new Field("Размер 1-2 года", "-", false, null));
            fields.Add(new Field("Размер 1-2,5 года", "-", false, null));
            fields.Add(new Field("Размер 1-3 года", "-", false, null));
            fields.Add(new Field("Размер 1-3 года", "-", false, null));
            fields.Add(new Field("Размер 1-4 года", "-", false, null));
            fields.Add(new Field("Размер 1-4 года", "-", false, null));
            fields.Add(new Field("Размер 1-5 лет", "-", false, null));
            fields.Add(new Field("Размер 1-5 лет", "-", false, null));
            fields.Add(new Field("Размер 1-5 лет", "-", false, null));
            fields.Add(new Field("Размер 1-5 лет", "-", false, null));
            fields.Add(new Field("Размер 1-6 лет", "-", false, null));
            fields.Add(new Field("Размер 1-6 лет", "-", false, null));
            fields.Add(new Field("Размер 1-6 лет", "-", false, null));
            fields.Add(new Field("Размер 12-18", "-", false, null));
            fields.Add(new Field("Размер 18-28", "-", false, null));
            fields.Add(new Field("Размер 2 года", "-", false, null));
            fields.Add(new Field("Размер 2-10 лет", "-", false, null));
            fields.Add(new Field("Размер 2-14 лет", "-", false, null));
            fields.Add(new Field("Размер 2-4 лет", "-", false, null));
            fields.Add(new Field("Размер 2-6 лет", "-", false, null));
            fields.Add(new Field("Размер 2-7 лет", "-", false, null));
            fields.Add(new Field("Размер 2-7 лет", "-", false, null));
            fields.Add(new Field("Размер 2-8 лет", "-", false, null));
            fields.Add(new Field("Размер 2-8 лет", "-", false, null));
            fields.Add(new Field("Размер 2-9 лет", "-", false, null));
            fields.Add(new Field("Размер 24-35", "-", false, null));
            fields.Add(new Field("Размер 24-37", "-", false, null));
            fields.Add(new Field("Размер 25-30", "-", false, null));
            fields.Add(new Field("Размер 25-31 ", "-", false, null));
            fields.Add(new Field("Размер 25-32", "-", false, null));
            fields.Add(new Field("Размер 25-34", "-", false, null));
            fields.Add(new Field("Размер 25-35", "-", false, null));
            fields.Add(new Field("Размер 25-36", "-", false, null));
            fields.Add(new Field("Размер 25-37", "-", false, null));
            fields.Add(new Field("Размер 26-30", "-", false, null));
            fields.Add(new Field("Размер 26-31", "-", false, null));
            fields.Add(new Field("Размер 26-32", "-", false, null));
            fields.Add(new Field("Размер 26-34", "-", false, null));
            fields.Add(new Field("Размер 27-34", "-", false, null));
            fields.Add(new Field("Размер 27-36", "-", false, null));
            fields.Add(new Field("Размер 28-34", "-", false, null));
            fields.Add(new Field("Размер 28-36", "-", false, null));
            fields.Add(new Field("Размер 28-36 без 35", "-", false, null));
            fields.Add(new Field("Размер 28-38", "-", false, null));
            fields.Add(new Field("Размер 28-40", "-", false, null));
            fields.Add(new Field("Размер 29-35", "-", false, null));
            fields.Add(new Field("Размер 29-36", "-", false, null));
            fields.Add(new Field("Размер 3-24 мес ", "-", false, null));
            fields.Add(new Field("Размер 3-7 лет", "-", false, null));
            fields.Add(new Field("Размер 3-8 лет", "-", false, null));
            fields.Add(new Field("Размер 30-35", "-", false, null));
            fields.Add(new Field("Размер 30-37", "-", false, null));
            fields.Add(new Field("Размер 30-40", "-", false, null));
            fields.Add(new Field("Размер 30-40 четные", "-", false, null));
            fields.Add(new Field("Размер 30-42", "-", false, null));
            fields.Add(new Field("Размер 31-36", "-", false, null));
            fields.Add(new Field("Размер 31-37", "-", false, null));
            fields.Add(new Field("Размер 34-38", "-", false, null));
            fields.Add(new Field("Размер 34-39", "-", false, null));
            fields.Add(new Field("Размер 35-38", "-", false, null));
            fields.Add(new Field("Размер 35-39", "-", false, null));
            fields.Add(new Field("Размер 35-40", "-", false, null));
            fields.Add(new Field("Размер 35-41", "-", false, null));
            fields.Add(new Field("Размер 35-42", "-", false, null));
            fields.Add(new Field("Размер 35-44", "-", false, null));
            fields.Add(new Field("Размер 35-46", "-", false, null));
            fields.Add(new Field("Размер 36-39", "-", false, null));
            fields.Add(new Field("Размер 36-40", "-", false, null));
            fields.Add(new Field("Размер 36-41", "-", false, null));
            fields.Add(new Field("Размер 36-42", "-", false, null));
            fields.Add(new Field("Размер 36-46", "-", false, null));
            fields.Add(new Field("Размер 38-43", "-", false, null));
            fields.Add(new Field("Размер 38-44", "-", false, null));
            fields.Add(new Field("Размер 38-45", "-", false, null));
            fields.Add(new Field("Размер 39-44", "-", false, null));
            fields.Add(new Field("Размер 39-44", "-", false, null));
            fields.Add(new Field("Размер 39-45", "-", false, null));
            fields.Add(new Field("Размер 39-46", "-", false, null));
            fields.Add(new Field("Размер 4-10 лет", "-", false, null));
            fields.Add(new Field("Размер 4-10 лет", "-", false, null));
            fields.Add(new Field("Размер 4-12 лет", "-", false, null));
            fields.Add(new Field("Размер 4-13 лет", "-", false, null));
            fields.Add(new Field("Размер 4-8 лет", "-", false, null));
            fields.Add(new Field("Размер 40-44", "-", false, null));
            fields.Add(new Field("Размер 40-45", "-", false, null));
            fields.Add(new Field("Размер 40-46", "-", false, null));
            fields.Add(new Field("Размер 40-47", "-", false, null));
            fields.Add(new Field("Размер 41", "-", false, null));
            fields.Add(new Field("Размер 41-45", "-", false, null));
            fields.Add(new Field("Размер 41-46", "-", false, null));
            fields.Add(new Field("Размер 41-47", "-", false, null));
            fields.Add(new Field("Размер 46-58", "-", false, null));
            fields.Add(new Field("Размер 5-10 лет", "-", false, null));
            fields.Add(new Field("Размер 5-12 лет", "-", false, null));
            fields.Add(new Field("Размер 5-16 лет", "-", false, null));
            fields.Add(new Field("Размер 5-6 лет", "-", false, null));
            fields.Add(new Field("Размер 5-8", "-", false, null));
            fields.Add(new Field("Размер 5-8 лет", "-", false, null));
            fields.Add(new Field("Размер 5-9 лет", "-", false, null));
            fields.Add(new Field("Размер 6-8 лет", "-", false, null));
            fields.Add(new Field("Размер 8-12", "-", false, null));
            fields.Add(new Field("Размер 8-14 лет", "-", false, null));
            fields.Add(new Field("Размер 9 -24 месяца", "-", false, null));
            fields.Add(new Field("Размер 9 мес-3 года", "-", false, null));
            fields.Add(new Field("Размер L", "-", false, null));
            fields.Add(new Field("Размер L-XL", "-", false, null));
            fields.Add(new Field("Размер L-XXL", "-", false, null));
            fields.Add(new Field("Размер L-XXXL", "-", false, null));
            fields.Add(new Field("Размер M-L", "-", false, null));
            fields.Add(new Field("Размер M-XL", "-", false, null));
            fields.Add(new Field("Размер M-XXL", "-", false, null));
            fields.Add(new Field("Размер M-XXXL", "-", false, null));
            fields.Add(new Field("Размер M-XXXXL", "-", false, null));
            fields.Add(new Field("Размер S", "-", false, null));
            fields.Add(new Field("Размер S-L", "-", false, null));
            fields.Add(new Field("Размер S-M", "-", false, null));
            fields.Add(new Field("Размер S-XL", "-", false, null));
            fields.Add(new Field("Размер S-XXL", "-", false, null));
            fields.Add(new Field("Размер S-XXXL", "-", false, null));
            fields.Add(new Field("Размер XL-XXL", "-", false, null));
            fields.Add(new Field("Размер XL-XXXL", "-", false, null));
            fields.Add(new Field("Размер XS-L", "-", false, null));
            fields.Add(new Field("Размер XS-M", "-", false, null));
            fields.Add(new Field("Размер XS-XL", "-", false, null));
            fields.Add(new Field("Размер XS-XXL", "-", false, null));
            fields.Add(new Field("Размер пакета", "-", false, null));
            fields.Add(new Field("Размерные ряды", "-", false, null));
            fields.Add(new Field("Размерный ряд", "-", false, null));
            fields.Add(new Field("Размеры", "-", false, null));
            fields.Add(new Field("Размеры 25-29", "-", false, null));
            fields.Add(new Field("Размеры 32-36", "-", false, null));
            fields.Add(new Field("Размеры 32B-36B", "-", false, null));
            fields.Add(new Field("Размеры 37-45", "-", false, null));
            fields.Add(new Field("Размеры пакетов", "-", false, null));
            fields.Add(new Field("Рост 100-130 см", "-", false, null));
            fields.Add(new Field("Рост 100-140 см", "-", false, null));
            fields.Add(new Field("Рост 100-170 см", "-", false, null));
            fields.Add(new Field("Рост 110-130 см", "-", false, null));
            fields.Add(new Field("Рост 110-155 см", "-", false, null));
            fields.Add(new Field("Рост 50-62 см", "-", false, null));
            fields.Add(new Field("Рост 62-86 см", "-", false, null));
            fields.Add(new Field("Рост 74-98 см", "-", false, null));
            fields.Add(new Field("Рост 80-120 см", "-", false, null));
            fields.Add(new Field("Рост 80-134 см", "-", false, null));
            fields.Add(new Field("Рост 80-95 см", "-", false, null));
            fields.Add(new Field("Рост 90-140 см", "-", false, null));
            fields.Add(new Field("Рост 90-95 см", "-", false, null));
            fields.Add(new Field("Рост 95", "-", false, null));
            fields.Add(new Field("Рост 95-140 см", "-", false, null));
            fields.Add(new Field("Рост 98-164 см", "-", false, null));
            fields.Add(new Field("Рост110-130см", "-", false, null));
            fields.Add(new Field("Рост110-140см", "-", false, null));
        }

        public void MakeHeader(StringBuilder sb)
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

        public void AddRow(StringBuilder sb, Dictionary<String,String> dic)
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
