using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

using FileHelpers;

namespace PriceProcessor.Controller
{

    [DelimitedRecord(";")]
    [IgnoreFirst(1)]
    class CsvNewProduct
    {
        [FieldQuoted('"', QuoteMode.OptionalForRead)]
        public string ProductCode;
        [FieldQuoted('"', QuoteMode.OptionalForRead)]
        public string ProductName;
    }

    [DelimitedRecord(";")]
    [IgnoreFirst(1)]
    class CsvApprovalItem
    {

        public const string HeaderLine = @"ItemID;Engine;Original name;Found name;Url;Price;Set '1' to approve or '0' to reject";

        [FieldQuoted('"', QuoteMode.OptionalForRead)]
        public long ItemID;

        [FieldQuoted('"', QuoteMode.OptionalForRead)]
        public string EngineName;

        [FieldQuoted('"', QuoteMode.OptionalForRead)]
        public string ProductName;

        [FieldQuoted('"', QuoteMode.OptionalForRead)]
        public string FoundName;
        
        [FieldQuoted('"', QuoteMode.OptionalForRead)]
        public string URL;
        
        [FieldQuoted('"', QuoteMode.OptionalForRead)]
        public string Price;
        
        [FieldQuoted('"', QuoteMode.OptionalForRead)]
        public string Command;
        
    }



}
