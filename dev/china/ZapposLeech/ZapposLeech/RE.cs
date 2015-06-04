using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

using System.Text.RegularExpressions;

namespace ZapposLeech
{
    class RE
    {
        public static Regex UriFilter = new Regex(@".+#!(.+)");

        public static Regex Products = new Regex(@"<a href=""(.+?)"" class=""product product-\d+");
        public static Regex Page = new Regex(@"<a href=""(.+?)"" class=""btn secondary arrow pager \d+"">&raquo;<\/a>");

        public static Regex ZapposOutOfStock = new Regex(@"var outOfStock = true;");
        public static Regex ZapposBrandName = new Regex(@"<h1 class=""title""><a href="".+?"" class=""brand"">(.+?)</a> <a href="".+?"" class=""link fn"">(.+?)</a></h1>");
        public static Regex ZapposPrice = new Regex(@"<span class=""price (nowPrice|salePrice)"">\$([0-9,]+\.\d\d)</span>");
        public static Regex ZapposOldPrice = new Regex(@"<span class=""oldPrice"">\$([0-9,]+\.\d\d)</span>");
        public static Regex ZapposStyleId = new Regex(@"var styleId = (\d+);");
        public static Regex ZapposSku = new Regex(@"<span id=""sku"" class=""sku id"">SKU (.+?)</span>");

        public static Regex ZapposSizeId = new Regex(@"""(d\d+)"":""size""");

        public static Regex ZapposSize = new Regex(@"<option value=""\d+"">(.+?)</option>");

        public static Regex CoutureBrandNameSku = new Regex(@"<h1 id=""prHead"">\s+<span class=""prName""><a href="".+?"">(.+?)</a> (.+?)</span>\s+<span class=""sku"">SKU: #(.+?)</span>\s+</h1>");
        public static Regex CouturePrice = new Regex(@"\$([0-9,]+\.\d\d)\s+</span>");
        public static Regex CoutureOldPrice = new Regex(@"<span class=""old-price"">\$([0-9,]+\.\d\d)</span>");
        public static Regex CouturePhotoSource = new Regex(@"<a href=""(.+?)"" title="".+?"" target=""_blank"" class=""multiview image"">");
        public static Regex CouturePhotos = new Regex(@"'4x': z\.imageBucket\('(.+?)'\),");

        public static Regex GetZapposPhotosLarge(string style)
        {
            return new Regex(@"pImgs\[" + style + @"\]\['4x'\]\['(.+?)'\] = \{ filename: '(.+?)'");
        }

        public static Regex GetZapposPhotosMedium(string style)
        {
            return new Regex(@"pImgs\[" + style + @"\]\['MULTIVIEW'\]\['(.+?)'\] = '(.+?)';");
        }

        public static Regex GetZapposSizeWrapper(string styleId)
        {
            return new Regex(@"<select id=""" + styleId + @""" class=""btn secondary"" name=""dimensionValues"">(.+?)</select>", RegexOptions.Singleline);
        }

        public static Regex GetZapposSingleSize(string styleId)
        {
            return new Regex(@"<input type=""hidden"" id=""" + styleId + @""" value="".+?"" name=""dimensionValues"" />\s+<p class=""note"">(.+?)</p>");
        }
    }
}
