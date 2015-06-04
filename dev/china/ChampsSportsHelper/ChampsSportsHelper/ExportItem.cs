using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Reflection;

using FileHelpers;

namespace ChampsSportsHelper
{
    // DO NOT USE PROPERTIES!

    [DelimitedRecord(";")]
    class ExportItem
    {
        public const string HEADERS = "Артикул;Наименование;Дополнительные категории;На складе;Цена;Описание;USA size;Ширина;" +
            "Фотография;Фотография;Фотография;Фотография;Фотография;Фотография;Фотография;Фотография;Фотография;Фотография;" +
            "Тип размерной таблицы;Старая цена";

        [FieldQuoted()]
        public string Sku;
        [FieldQuoted()]
        public string Name;
        public string MoreCategories;
        public int InStock = 1;
        public string Price;
        [FieldQuoted()]
        public string Description;
        public string Size;
        [FieldQuoted()]
        public string Width;
        public string Photo0;
        public string Photo1;
        public string Photo2;
        public string Photo3;
        public string Photo4;
        public string Photo5;
        public string Photo6;
        public string Photo7;
        public string Photo8;
        public string Photo9;
        [FieldQuoted()]
        public string SizeChartType;
        public string OldPrice;

        public void SetPhoto(int index, string value)
        {
            string fldName = "Photo" + index;
            FieldInfo fi = this.GetType().GetField(fldName, BindingFlags.Public | BindingFlags.Instance);
            if (null != fi)
            {
                fi.SetValue(this, value);
            }
        }


    }
}
