using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace ShopProcessor.CSV
{
    public class FieldList : List<Field>
    {
        private static FieldList fields;

        private static List<Field> custom_fields;

        static FieldList()
        {
            Object x = FileHelper.Deserialize(typeof(FieldList), FileHelper.FieldsXml());
            if (x != null)
            {
                custom_fields = (FieldList)x;
            }
            else
            {
                custom_fields = new FieldList();
            }
            
        }

        public static FieldList GetFields()
        {
            if (fields == null)
            {
                fields = new FieldList();

                fields.Add(new Field("Артикул", Field.Article, true, null, true, false));
                fields.Add(new Field("Наименование", Field.Name, false, null, true, false));
                fields.Add(new Field("ID страницы (часть URL; используется в ссылках на эту страницу)", "f8508c53-7091-4cbb-a756-be91587a59b8", false, null, false, true));
                fields.Add(new Field("Цена", "4370ccd9-3f93-4f44-a0cf-a0fdfc56cbdf", false, "0.01", true, false));
                fields.Add(new Field("Название вида налогов", "f05a1a80-05c1-4670-bf7a-3ec0200bc24b", false, null, false, true));
                fields.Add(new Field("Скрытый", "215aca28-9f46-4352-9e0d-871ddc401a90", false, null, false, true));
                fields.Add(new Field("Можно купить", "eeb81bd6-e3a8-47d4-aa1c-cf41e0567ae8", false, "1", false, true));
                fields.Add(new Field("Старая цена", "b88640f3-7189-46c4-8170-49e9791a51de", false, "0", false, true));
                fields.Add(new Field("Продано", "5858e7b6-f88e-4e59-b89f-bbb05a66fd84", false, "0", false, true));
                fields.Add(new Field("Описание", "b92f0c3b-6d65-4e7b-a9f6-84b9413d6465", true, null, true, false));
                fields.Add(new Field("Краткое описание", "c9c9ca82-09f3-4f40-918f-c2e09c3cdca3", false, null, true, false));
                fields.Add(new Field("Сортировка", "c1db4513-a1c8-4b33-a366-8a770fcf2051", false, "0", false, true));
                fields.Add(new Field("Заголовок страницы", "8e32b323-bea0-476e-af1c-203f53961fb2", false, null, true, false));
                fields.Add(new Field("Тэг META keywords", "a661001b-2f68-47f3-bf18-4d32cec9c70b", false, null, true, false));
                fields.Add(new Field("Тэг META description", "d6c67129-f229-4715-94a2-fa8e809e3428", false, null, true, false));
                fields.Add(new Field("Стоимость упаковки", "1abc0967-cdde-4f66-8bc6-14a51b2be74b", false, "0", false, true));
                fields.Add(new Field("Вес продукта", "3fe1d724-d8d9-4fea-866d-6fdb412c40bd", false, "0", false, true));
                fields.Add(new Field("Бесплатная доставка", "c1446810-350f-40a2-bbd1-8fee9355cdb4", false, "0", false, true));
                fields.Add(new Field("Ограничение на минимальный заказ продукта (штук)", "947e2df4-a5ab-4d7c-95f3-6815cd1d672e", false, "1", true, false));
                fields.Add(new Field("Файл продукта", "de254b3d-a56a-4d0a-a971-643d59e1d112", false, null, false, true));
                fields.Add(new Field("Количество дней для скачивания", "dbcf1141-2a4a-4da3-991d-ac1f2d08290d", false, "5", false, true));
                fields.Add(new Field("Количество загрузок (раз)", "68f636b1-601e-4cf1-ba47-24455c0bc4c9", false, "5", false, true));

                fields.Add(new Field("Фотография", Field.PhotoName(0), true, null, false, true));
                fields.Add(new Field("Фотография", Field.PhotoName(1), true, null, false, true));
                fields.Add(new Field("Фотография", Field.PhotoName(2), true, null, false, true));
                fields.Add(new Field("Фотография", Field.PhotoName(3), true, null, false, true));
                fields.Add(new Field("Фотография", Field.PhotoName(4), true, null, false, true));
                fields.Add(new Field("Фотография", Field.PhotoName(5), true, null, false, true));
                fields.Add(new Field("Фотография", Field.PhotoName(6), true, null, false, true));
                fields.Add(new Field("Фотография", Field.PhotoName(7), true, null, false, true));
                fields.Add(new Field("Фотография", Field.PhotoName(8), true, null, false, true));
                fields.Add(new Field("Фотография", Field.PhotoName(9), true, null, false, true));
                fields.Add(new Field("Фотография", Field.PhotoName(10), true, null, false, true));
                fields.Add(new Field("Фотография", Field.PhotoName(11), true, null, false, true));
                fields.Add(new Field("Фотография", Field.PhotoName(12), true, null, false, true));
                fields.Add(new Field("Фотография", Field.PhotoName(13), true, null, false, true));
                fields.Add(new Field("Фотография", Field.PhotoName(14), true, null, false, true));
                fields.Add(new Field("Фотография", Field.PhotoName(15), true, null, false, true));


                fields.Add(new Field("0-12 мес.", "3A0DB523-6BFE-1014-B09E-8C13620781A9", false, null));
                fields.Add(new Field("0-3 лет", "3A0DB55F-6BFE-1014-B09E-8C13620781A9", false, null));
                fields.Add(new Field("1-11 лет", "3A0DB58F-6BFE-1014-B09E-8C13620781A9", false, null));
                fields.Add(new Field("1-2 лет", "3A0DB5BE-6BFE-1014-B09E-8C13620781A9", false, null));
                fields.Add(new Field("1-6 лет", "3A0DB5ED-6BFE-1014-B09E-8C13620781A9", false, null));
                fields.Add(new Field("1.5-6 лет", "3A0DB61D-6BFE-1014-B09E-8C13620781A9", false, null));
                fields.Add(new Field("2-10 лет", "3A0DB64E-6BFE-1014-B09E-8C13620781A9", false, null));
                fields.Add(new Field("2-14 лет", "3A0DB67D-6BFE-1014-B09E-8C13620781A9", false, null));
                fields.Add(new Field("2-18 мес.", "3A0DB6AB-6BFE-1014-B09E-8C13620781A9", false, null));
                fields.Add(new Field("2-3 года", "3A0DB6DC-6BFE-1014-B09E-8C13620781A9", false, null));
                fields.Add(new Field("2-8 лет", "3A0DB70D-6BFE-1014-B09E-8C13620781A9", false, null));
                fields.Add(new Field("3-13 лет", "3A0DB73C-6BFE-1014-B09E-8C13620781A9", false, null));
                fields.Add(new Field("3-24 мес.", "3A0DB76A-6BFE-1014-B09E-8C13620781A9", false, null));
                fields.Add(new Field("3-5 лет", "3A0DB79B-6BFE-1014-B09E-8C13620781A9", false, null));
                fields.Add(new Field("3-6 лет", "3A0DB7CA-6BFE-1014-B09E-8C13620781A9", false, null));
                fields.Add(new Field("3мес.-3лет", "3A0DB7FA-6BFE-1014-B09E-8C13620781A9", false, null));
                fields.Add(new Field("4-14 лет", "3A0DB82B-6BFE-1014-B09E-8C13620781A9", false, null));
                fields.Add(new Field("4-16 лет", "3A0DB85A-6BFE-1014-B09E-8C13620781A9", false, null));
                fields.Add(new Field("4-18 мес.", "3A0DB888-6BFE-1014-B09E-8C13620781A9", false, null));
                fields.Add(new Field("4-6 лет", "3A0DB8B9-6BFE-1014-B09E-8C13620781A9", false, null));
                fields.Add(new Field("4-8 лет", "3A0DB8E8-6BFE-1014-B09E-8C13620781A9", false, null));
                fields.Add(new Field("5-15 лет", "3A0DB917-6BFE-1014-B09E-8C13620781A9", false, null));
                fields.Add(new Field("5-8 мес.", "3A0DB946-6BFE-1014-B09E-8C13620781A9", false, null));
                fields.Add(new Field("5-9 лет", "3A0DB975-6BFE-1014-B09E-8C13620781A9", false, null));
                fields.Add(new Field("6-16 лет", "3A0DB9A4-6BFE-1014-B09E-8C13620781A9", false, null));
                fields.Add(new Field("7-10 лет", "3A0DB9D3-6BFE-1014-B09E-8C13620781A9", false, null));
                fields.Add(new Field("7-12 лет", "3A0DBA01-6BFE-1014-B09E-8C13620781A9", false, null));
                fields.Add(new Field("9-24 мес.", "3A0DBA30-6BFE-1014-B09E-8C13620781A9", false, null));
                fields.Add(new Field("9мес.-2 лет", "3A0DBA60-6BFE-1014-B09E-8C13620781A9", false, null));
                fields.Add(new Field("UK0-16", "3A0DBA92-6BFE-1014-B09E-8C13620781A9", false, null));
                fields.Add(new Field("Длина стопы 10,5-13,5 см", "3A0DBAC0-6BFE-1014-B09E-8C13620781A9", false, null));
                fields.Add(new Field("Длина стопы 10.5см-13.5 см", "3A0DBAF6-6BFE-1014-B09E-8C13620781A9", false, null));
                fields.Add(new Field("Длина стопы 11.5см-13.5 cm", "3A0DBB2B-6BFE-1014-B09E-8C13620781A9", false, null));
                fields.Add(new Field("Длина стопы 12.5см-16.1см", "3A0DBB5F-6BFE-1014-B09E-8C13620781A9", false, null));
                fields.Add(new Field("Длина стопы 12.8см-15.2см", "3A0DBB94-6BFE-1014-B09E-8C13620781A9", false, null));
                fields.Add(new Field("Длина стопы 12см-14см", "3A0DBBC8-6BFE-1014-B09E-8C13620781A9", false, null));
                fields.Add(new Field("Длина стопы 13.4см-15.8см", "3A0DBBFD-6BFE-1014-B09E-8C13620781A9", false, null));
                fields.Add(new Field("Длина стопы 13.4см-16.4см ", "3A0DBC31-6BFE-1014-B09E-8C13620781A9", false, null));
                fields.Add(new Field("Длина стопы 13.5-17см", "3A0DBC66-6BFE-1014-B09E-8C13620781A9", false, null));
                fields.Add(new Field("Длина стопы 14-16.5см", "3A0DBC9A-6BFE-1014-B09E-8C13620781A9", false, null));
                fields.Add(new Field("Длина стопы 15-20см", "3A0DBCCE-6BFE-1014-B09E-8C13620781A9", false, null));
                fields.Add(new Field("Длина стопы 15-22см", "3A0DBD02-6BFE-1014-B09E-8C13620781A9", false, null));
                fields.Add(new Field("Единый размер", "3A0DBD93-6BFE-1014-B09E-8C13620781A9", false, null));
                fields.Add(new Field("Размер", "3A0DBDCD-6BFE-1014-B09E-8C13620781A9", false, null));
                fields.Add(new Field("Размер 0,5-2 года", "3A0DBDFE-6BFE-1014-B09E-8C13620781A9", false, null));
                fields.Add(new Field("Размер 0,5-3 года", "3A0DBE32-6BFE-1014-B09E-8C13620781A9", false, null));
                fields.Add(new Field("Размер 0-3", "3A0DBE65-6BFE-1014-B09E-8C13620781A9", false, null));
                fields.Add(new Field("Размер 0-3 года", "3A0DBE96-6BFE-1014-B09E-8C13620781A9", false, null));
                fields.Add(new Field("Размер 1,5-3 года", "3A0DBEC9-6BFE-1014-B09E-8C13620781A9", false, null));
                fields.Add(new Field("Размер 1,5-5 лет", "3A0DBEFC-6BFE-1014-B09E-8C13620781A9", false, null));
                fields.Add(new Field("Размер 1,5-6 лет", "3A0DBF2E-6BFE-1014-B09E-8C13620781A9", false, null));
                fields.Add(new Field("Размер 1,5-7 лет", "3A0DBF60-6BFE-1014-B09E-8C13620781A9", false, null));
                fields.Add(new Field("Размер 1-12 лет", "3A0DBF93-6BFE-1014-B09E-8C13620781A9", false, null));
                fields.Add(new Field("Размер 1-2 года", "3A0DBFC5-6BFE-1014-B09E-8C13620781A9", false, null));
                fields.Add(new Field("Размер 1-2,5 года", "3A0DBFF8-6BFE-1014-B09E-8C13620781A9", false, null));
                fields.Add(new Field("Размер 1-3 года", "3A0DC03C-6BFE-1014-B09E-8C13620781A9", false, null));
                fields.Add(new Field("Размер 1-3 года", "3A0DC06E-6BFE-1014-B09E-8C13620781A9", false, null));
                fields.Add(new Field("Размер 1-4 года", "3A0DC0A1-6BFE-1014-B09E-8C13620781A9", false, null));
                fields.Add(new Field("Размер 1-4 года", "3A0DC0D3-6BFE-1014-B09E-8C13620781A9", false, null));
                fields.Add(new Field("Размер 1-5 лет", "3A0DC105-6BFE-1014-B09E-8C13620781A9", false, null));
                fields.Add(new Field("Размер 1-5 лет", "3A0DC138-6BFE-1014-B09E-8C13620781A9", false, null));
                fields.Add(new Field("Размер 1-5 лет", "3A0DC16A-6BFE-1014-B09E-8C13620781A9", false, null));
                fields.Add(new Field("Размер 1-5 лет", "3A0DC19C-6BFE-1014-B09E-8C13620781A9", false, null));
                fields.Add(new Field("Размер 1-6 лет", "3A0DC1CE-6BFE-1014-B09E-8C13620781A9", false, null));
                fields.Add(new Field("Размер 1-6 лет", "3A0DC202-6BFE-1014-B09E-8C13620781A9", false, null));
                fields.Add(new Field("Размер 1-6 лет", "3A0DC234-6BFE-1014-B09E-8C13620781A9", false, null));
                fields.Add(new Field("Размер 12-18", "3A0DC266-6BFE-1014-B09E-8C13620781A9", false, null));
                fields.Add(new Field("Размер 18-28", "3A0DC297-6BFE-1014-B09E-8C13620781A9", false, null));
                fields.Add(new Field("Размер 2 года", "3A0DC2C9-6BFE-1014-B09E-8C13620781A9", false, null));
                fields.Add(new Field("Размер 2-10 лет", "3A0DC2FB-6BFE-1014-B09E-8C13620781A9", false, null));
                fields.Add(new Field("Размер 2-14 лет", "3A0DC32D-6BFE-1014-B09E-8C13620781A9", false, null));
                fields.Add(new Field("Размер 2-4 лет", "3A0DC360-6BFE-1014-B09E-8C13620781A9", false, null));
                fields.Add(new Field("Размер 2-6 лет", "3A0DC392-6BFE-1014-B09E-8C13620781A9", false, null));
                fields.Add(new Field("Размер 2-7 лет", "3A0DC3C4-6BFE-1014-B09E-8C13620781A9", false, null));
                fields.Add(new Field("Размер 2-7 лет", "3A0DC3F6-6BFE-1014-B09E-8C13620781A9", false, null));
                fields.Add(new Field("Размер 2-8 лет", "3A0DC428-6BFE-1014-B09E-8C13620781A9", false, null));
                fields.Add(new Field("Размер 2-8 лет", "3A0DC45A-6BFE-1014-B09E-8C13620781A9", false, null));
                fields.Add(new Field("Размер 2-9 лет", "3A0DC48B-6BFE-1014-B09E-8C13620781A9", false, null));
                fields.Add(new Field("Размер 24-35", "3A0DC4BD-6BFE-1014-B09E-8C13620781A9", false, null));
                fields.Add(new Field("Размер 24-37", "3A0DC4EF-6BFE-1014-B09E-8C13620781A9", false, null));
                fields.Add(new Field("Размер 25-30", "3A0DC520-6BFE-1014-B09E-8C13620781A9", false, null));
                fields.Add(new Field("Размер 25-31 ", "3A0DC567-6BFE-1014-B09E-8C13620781A9", false, null));
                fields.Add(new Field("Размер 25-32", "3A0DC59C-6BFE-1014-B09E-8C13620781A9", false, null));
                fields.Add(new Field("Размер 25-34", "3A0DC5CE-6BFE-1014-B09E-8C13620781A9", false, null));
                fields.Add(new Field("Размер 25-35", "3A0DC5FF-6BFE-1014-B09E-8C13620781A9", false, null));
                fields.Add(new Field("Размер 25-36", "3A0DC630-6BFE-1014-B09E-8C13620781A9", false, null));
                fields.Add(new Field("Размер 25-37", "3A0DC662-6BFE-1014-B09E-8C13620781A9", false, null));
                fields.Add(new Field("Размер 26-30", "3A0DC693-6BFE-1014-B09E-8C13620781A9", false, null));
                fields.Add(new Field("Размер 26-31", "3A0DC6C4-6BFE-1014-B09E-8C13620781A9", false, null));
                fields.Add(new Field("Размер 26-32", "3A0DC6F5-6BFE-1014-B09E-8C13620781A9", false, null));
                fields.Add(new Field("Размер 26-34", "3A0DC726-6BFE-1014-B09E-8C13620781A9", false, null));
                fields.Add(new Field("Размер 27-34", "3A0DC757-6BFE-1014-B09E-8C13620781A9", false, null));
                fields.Add(new Field("Размер 27-36", "3A0DC789-6BFE-1014-B09E-8C13620781A9", false, null));
                fields.Add(new Field("Размер 28-34", "3A0DC7BA-6BFE-1014-B09E-8C13620781A9", false, null));
                fields.Add(new Field("Размер 28-36", "3A0DC7EB-6BFE-1014-B09E-8C13620781A9", false, null));
                fields.Add(new Field("Размер 28-36 без 35", "3A0DC81C-6BFE-1014-B09E-8C13620781A9", false, null));
                fields.Add(new Field("Размер 28-38", "3A0DC84F-6BFE-1014-B09E-8C13620781A9", false, null));
                fields.Add(new Field("Размер 28-40", "3A0DC880-6BFE-1014-B09E-8C13620781A9", false, null));
                fields.Add(new Field("Размер 29-35", "3A0DC8B2-6BFE-1014-B09E-8C13620781A9", false, null));
                fields.Add(new Field("Размер 29-36", "3A0DC8E3-6BFE-1014-B09E-8C13620781A9", false, null));
                fields.Add(new Field("Размер 3-24 мес ", "3A0DC914-6BFE-1014-B09E-8C13620781A9", false, null));
                fields.Add(new Field("Размер 3-7 лет", "3A0DC947-6BFE-1014-B09E-8C13620781A9", false, null));
                fields.Add(new Field("Размер 3-8 лет", "3A0DC979-6BFE-1014-B09E-8C13620781A9", false, null));
                fields.Add(new Field("Размер 30-35", "3A0DC9AC-6BFE-1014-B09E-8C13620781A9", false, null));
                fields.Add(new Field("Размер 30-37", "3A0DC9DD-6BFE-1014-B09E-8C13620781A9", false, null));
                fields.Add(new Field("Размер 30-40", "3A0DCA0E-6BFE-1014-B09E-8C13620781A9", false, null));
                fields.Add(new Field("Размер 30-40 четные", "3A0DCA40-6BFE-1014-B09E-8C13620781A9", false, null));
                fields.Add(new Field("Размер 30-42", "3A0DCA73-6BFE-1014-B09E-8C13620781A9", false, null));
                fields.Add(new Field("Размер 31-36", "3A0DCAA5-6BFE-1014-B09E-8C13620781A9", false, null));
                fields.Add(new Field("Размер 31-37", "3A0DCAD6-6BFE-1014-B09E-8C13620781A9", false, null));
                fields.Add(new Field("Размер 34-38", "3A0DCB08-6BFE-1014-B09E-8C13620781A9", false, null));
                fields.Add(new Field("Размер 34-39", "3A0DCB39-6BFE-1014-B09E-8C13620781A9", false, null));
                fields.Add(new Field("Размер 35-38", "3A0DCB6A-6BFE-1014-B09E-8C13620781A9", false, null));
                fields.Add(new Field("Размер 35-39", "3A0DCB9C-6BFE-1014-B09E-8C13620781A9", false, null));
                fields.Add(new Field("Размер 35-40", "3A0DCBCD-6BFE-1014-B09E-8C13620781A9", false, null));
                fields.Add(new Field("Размер 35-41", "3A0DCBFE-6BFE-1014-B09E-8C13620781A9", false, null));
                fields.Add(new Field("Размер 35-42", "3A0DCC2F-6BFE-1014-B09E-8C13620781A9", false, null));
                fields.Add(new Field("Размер 35-44", "3A0DCC61-6BFE-1014-B09E-8C13620781A9", false, null));
                fields.Add(new Field("Размер 35-46", "3A0DCC92-6BFE-1014-B09E-8C13620781A9", false, null));
                fields.Add(new Field("Размер 36-39", "3A0DCCC3-6BFE-1014-B09E-8C13620781A9", false, null));
                fields.Add(new Field("Размер 36-40", "3A0DCCF4-6BFE-1014-B09E-8C13620781A9", false, null));
                fields.Add(new Field("Размер 36-41", "3A0DCD36-6BFE-1014-B09E-8C13620781A9", false, null));
                fields.Add(new Field("Размер 36-42", "3A0DCD7C-6BFE-1014-B09E-8C13620781A9", false, null));
                fields.Add(new Field("Размер 36-46", "3A0DCDB1-6BFE-1014-B09E-8C13620781A9", false, null));
                fields.Add(new Field("Размер 38-43", "3A0DCDE2-6BFE-1014-B09E-8C13620781A9", false, null));
                fields.Add(new Field("Размер 38-44", "3A0DCE13-6BFE-1014-B09E-8C13620781A9", false, null));
                fields.Add(new Field("Размер 38-45", "3A0DCE44-6BFE-1014-B09E-8C13620781A9", false, null));
                fields.Add(new Field("Размер 39-44", "3A0DCE75-6BFE-1014-B09E-8C13620781A9", false, null));
                fields.Add(new Field("Размер 39-44", "3A0DCEA6-6BFE-1014-B09E-8C13620781A9", false, null));
                fields.Add(new Field("Размер 39-45", "3A0DCED7-6BFE-1014-B09E-8C13620781A9", false, null));
                fields.Add(new Field("Размер 39-46", "3A0DCF08-6BFE-1014-B09E-8C13620781A9", false, null));
                fields.Add(new Field("Размер 4-10 лет", "3A0DCF39-6BFE-1014-B09E-8C13620781A9", false, null));
                fields.Add(new Field("Размер 4-10 лет", "3A0DCF6C-6BFE-1014-B09E-8C13620781A9", false, null));
                fields.Add(new Field("Размер 4-12 лет", "3A0DCF9E-6BFE-1014-B09E-8C13620781A9", false, null));
                fields.Add(new Field("Размер 4-13 лет", "3A0DCFD1-6BFE-1014-B09E-8C13620781A9", false, null));
                fields.Add(new Field("Размер 4-8 лет", "3A0DD003-6BFE-1014-B09E-8C13620781A9", false, null));
                fields.Add(new Field("Размер 40-44", "3A0DD035-6BFE-1014-B09E-8C13620781A9", false, null));
                fields.Add(new Field("Размер 40-45", "3A0DD066-6BFE-1014-B09E-8C13620781A9", false, null));
                fields.Add(new Field("Размер 40-46", "3A0DD097-6BFE-1014-B09E-8C13620781A9", false, null));
                fields.Add(new Field("Размер 40-47", "3A0DD0C8-6BFE-1014-B09E-8C13620781A9", false, null));
                fields.Add(new Field("Размер 41", "3A0DD0F9-6BFE-1014-B09E-8C13620781A9", false, null));
                fields.Add(new Field("Размер 41-45", "3A0DD12A-6BFE-1014-B09E-8C13620781A9", false, null));
                fields.Add(new Field("Размер 41-46", "3A0DD15B-6BFE-1014-B09E-8C13620781A9", false, null));
                fields.Add(new Field("Размер 41-47", "3A0DD18C-6BFE-1014-B09E-8C13620781A9", false, null));
                fields.Add(new Field("Размер 46-58", "3A0DD1BD-6BFE-1014-B09E-8C13620781A9", false, null));
                fields.Add(new Field("Размер 5-10 лет", "3A0DD1EE-6BFE-1014-B09E-8C13620781A9", false, null));
                fields.Add(new Field("Размер 5-12 лет", "3A0DD220-6BFE-1014-B09E-8C13620781A9", false, null));
                fields.Add(new Field("Размер 5-16 лет", "3A0DD253-6BFE-1014-B09E-8C13620781A9", false, null));
                fields.Add(new Field("Размер 5-6 лет", "3A0DD285-6BFE-1014-B09E-8C13620781A9", false, null));
                fields.Add(new Field("Размер 5-8", "3A0DD2B7-6BFE-1014-B09E-8C13620781A9", false, null));
                fields.Add(new Field("Размер 5-8 лет", "3A0DD2E8-6BFE-1014-B09E-8C13620781A9", false, null));
                fields.Add(new Field("Размер 5-9 лет", "3A0DD31A-6BFE-1014-B09E-8C13620781A9", false, null));
                fields.Add(new Field("Размер 6-8 лет", "3A0DD34C-6BFE-1014-B09E-8C13620781A9", false, null));
                fields.Add(new Field("Размер 8-12", "3A0DD37E-6BFE-1014-B09E-8C13620781A9", false, null));
                fields.Add(new Field("Размер 8-14 лет", "3A0DD3AF-6BFE-1014-B09E-8C13620781A9", false, null));
                fields.Add(new Field("Размер 9 -24 месяца", "3A0DD3E2-6BFE-1014-B09E-8C13620781A9", false, null));
                fields.Add(new Field("Размер 9 мес-3 года", "3A0DD415-6BFE-1014-B09E-8C13620781A9", false, null));
                fields.Add(new Field("Размер L", "3A0DD449-6BFE-1014-B09E-8C13620781A9", false, null));
                fields.Add(new Field("Размер L-XL", "3A0DD479-6BFE-1014-B09E-8C13620781A9", false, null));
                fields.Add(new Field("Размер L-XXL", "3A0DD4AB-6BFE-1014-B09E-8C13620781A9", false, null));
                fields.Add(new Field("Размер L-XXXL", "3A0DD4DC-6BFE-1014-B09E-8C13620781A9", false, null));
                fields.Add(new Field("Размер M-L", "3A0DD50E-6BFE-1014-B09E-8C13620781A9", false, null));
                fields.Add(new Field("Размер M-XL", "3A0DD58F-6BFE-1014-B09E-8C13620781A9", false, null));
                fields.Add(new Field("Размер M-XXL", "3A0DD5C7-6BFE-1014-B09E-8C13620781A9", false, null));
                fields.Add(new Field("Размер M-XXXL", "3A0DD5F9-6BFE-1014-B09E-8C13620781A9", false, null));
                fields.Add(new Field("Размер M-XXXXL", "3A0DD62A-6BFE-1014-B09E-8C13620781A9", false, null));
                fields.Add(new Field("Размер S", "3A0DD65C-6BFE-1014-B09E-8C13620781A9", false, null));
                fields.Add(new Field("Размер S-L", "3A0DD68D-6BFE-1014-B09E-8C13620781A9", false, null));
                fields.Add(new Field("Размер S-M", "3A0DD6BE-6BFE-1014-B09E-8C13620781A9", false, null));
                fields.Add(new Field("Размер S-XL", "3A0DD6F0-6BFE-1014-B09E-8C13620781A9", false, null));
                fields.Add(new Field("Размер S-XXL", "3A0DD721-6BFE-1014-B09E-8C13620781A9", false, null));
                fields.Add(new Field("Размер S-XXXL", "3A0DD752-6BFE-1014-B09E-8C13620781A9", false, null));
                fields.Add(new Field("Размер XL-XXL", "3A0DD784-6BFE-1014-B09E-8C13620781A9", false, null));
                fields.Add(new Field("Размер XL-XXXL", "3A0DD7B5-6BFE-1014-B09E-8C13620781A9", false, null));
                fields.Add(new Field("Размер XS-L", "3A0DD7E7-6BFE-1014-B09E-8C13620781A9", false, null));
                fields.Add(new Field("Размер XS-M", "3A0DD818-6BFE-1014-B09E-8C13620781A9", false, null));
                fields.Add(new Field("Размер XS-XL", "3A0DD849-6BFE-1014-B09E-8C13620781A9", false, null));
                fields.Add(new Field("Размер XS-XXL", "3A0DD87B-6BFE-1014-B09E-8C13620781A9", false, null));
                fields.Add(new Field("Размер пакета", "3A0DD8AC-6BFE-1014-B09E-8C13620781A9", false, null));
                fields.Add(new Field("Размерные ряды", "3A0DD8DF-6BFE-1014-B09E-8C13620781A9", false, null));
                fields.Add(new Field("Размерный ряд", "3A0DD912-6BFE-1014-B09E-8C13620781A9", false, null));
                fields.Add(new Field("Размеры", "3A0DD944-6BFE-1014-B09E-8C13620781A9", false, null));
                fields.Add(new Field("Размеры 25-29", "3A0DD975-6BFE-1014-B09E-8C13620781A9", false, null));
                fields.Add(new Field("Размеры 32-36", "3A0DD9A7-6BFE-1014-B09E-8C13620781A9", false, null));
                fields.Add(new Field("Размеры 32B-36B", "3A0DD9D8-6BFE-1014-B09E-8C13620781A9", false, null));
                fields.Add(new Field("Размеры 37-45", "3A0DDA0A-6BFE-1014-B09E-8C13620781A9", false, null));
                fields.Add(new Field("Размеры пакетов", "3A0DDA62-6BFE-1014-B09E-8C13620781A9", false, null));
                fields.Add(new Field("Рост 100-130 см", "3A0DDA95-6BFE-1014-B09E-8C13620781A9", false, null));
                fields.Add(new Field("Рост 100-140 см", "3A0DDAC7-6BFE-1014-B09E-8C13620781A9", false, null));
                fields.Add(new Field("Рост 100-170 см", "3A0DDAF8-6BFE-1014-B09E-8C13620781A9", false, null));
                fields.Add(new Field("Рост 110-130 см", "3A0DDB2A-6BFE-1014-B09E-8C13620781A9", false, null));
                fields.Add(new Field("Рост 110-155 см", "3A0DDB5C-6BFE-1014-B09E-8C13620781A9", false, null));
                fields.Add(new Field("Рост 50-62 см", "3A0DDB8E-6BFE-1014-B09E-8C13620781A9", false, null));
                fields.Add(new Field("Рост 62-86 см", "3A0DDBC0-6BFE-1014-B09E-8C13620781A9", false, null));
                fields.Add(new Field("Рост 74-98 см", "3A0DDBF1-6BFE-1014-B09E-8C13620781A9", false, null));
                fields.Add(new Field("Рост 80-120 см", "3A0DDC23-6BFE-1014-B09E-8C13620781A9", false, null));
                fields.Add(new Field("Рост 80-134 см", "3A0DDC56-6BFE-1014-B09E-8C13620781A9", false, null));
                fields.Add(new Field("Рост 80-95 см", "3A0DDC88-6BFE-1014-B09E-8C13620781A9", false, null));
                fields.Add(new Field("Рост 90-140 см", "3A0DDCB9-6BFE-1014-B09E-8C13620781A9", false, null));
                fields.Add(new Field("Рост 90-95 см", "3A0DDCEB-6BFE-1014-B09E-8C13620781A9", false, null));
                fields.Add(new Field("Рост 95", "3A0DDD1D-6BFE-1014-B09E-8C13620781A9", false, null));
                fields.Add(new Field("Рост 95-140 см", "3A0DDD4C-6BFE-1014-B09E-8C13620781A9", false, null));
                fields.Add(new Field("Рост 98-164 см", "3A0DDD7F-6BFE-1014-B09E-8C13620781A9", false, null));
                fields.Add(new Field("Рост110-130см", "3A0DDDC6-6BFE-1014-B09E-8C13620781A9", false, null));
                fields.Add(new Field("Рост110-140см", "3A0DDDFB-6BFE-1014-B09E-8C13620781A9", false, null));

                fields.AddRange(custom_fields);
            }

            return fields;

        }

        public static void SaveCustomFields()
        {
            FileHelper.Serialize(custom_fields, FileHelper.FieldsXml());
        }

        public static void AddCustomField(Field f)
        {
            custom_fields.Add(f);
            fields.Add(f);
        }

        public static void RemoveCustomField(Field f)
        {
            custom_fields.Remove(f);
            fields.Remove(f);
        }

        // hide the constructor due to the "Factory" pattern
        private FieldList() { }

    }
}
