using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

using System.Drawing;
using System.Drawing.Imaging;
using System.Drawing.Text;
using System.Drawing.Drawing2D;

namespace ZapposLeech
{
    class Painter
    {

        public static bool ApplyPhoto(string imageName, Photo photo, Config cfg, string destinationName)
        {
            int brSize = cfg.BrandSize;
            int nmSize = cfg.NameSize;
            int btmSize = cfg.BottomSize;

            if (photo.PhotoSize == PhotoSize.Medium)
            {
                // divide to 4
                brSize = (int)(brSize / 3);
                nmSize = (int)(nmSize / 3);
                btmSize = (int)(btmSize / 3);
            }

            Font fntBrand = new Font(cfg.Family, brSize);
            Font fntName = new Font(cfg.Family, nmSize);
            Font fntBottom = new Font(cfg.Family, btmSize);
            Font fntOldPrice = new Font(cfg.Family, btmSize, FontStyle.Strikeout);

            Brush brshTextRegular = new SolidBrush(Color.Blue);
            Brush brshBackground = new SolidBrush(Color.White);
            Brush brshPrice = new SolidBrush(Color.Red);
            Brush brshFillBottom = new SolidBrush(Color.Gray);

            ImageCodecInfo codecInfo = ImageCodecInfo.GetImageDecoders().FirstOrDefault(x => x.FormatID == ImageFormat.Jpeg.Guid);
            if (codecInfo == default(ImageCodecInfo))
                throw new Exception("Cannot find the Jped encoder");

            System.Drawing.Imaging.Encoder qualityEncoder = System.Drawing.Imaging.Encoder.Quality;
            EncoderParameters  encoderParameters = new EncoderParameters(1);
            EncoderParameter myEncoderParameter = new EncoderParameter(qualityEncoder, 90L);
            encoderParameters.Param[0] = myEncoderParameter;


            try
            {
                using (Image org = Image.FromFile(imageName))
                using (Image tempOrg = new Bitmap(org))
                using (Graphics graph = Graphics.FromImage(tempOrg))
                {
                    // print the brand name
                    SizeF szBrand = graph.MeasureString(photo.Brand, fntBrand);
                    graph.FillRectangle(brshBackground, 0, 0, szBrand.Width, szBrand.Height);
                    graph.DrawString(photo.Brand, fntBrand, brshTextRegular, 0, 0);

                    // print the product name
                    SizeF szName = graph.MeasureString(photo.Name, fntName);
                    graph.FillRectangle(brshBackground, 0, szBrand.Height, szName.Width, szName.Height);
                    graph.DrawString(photo.Name, fntName, brshTextRegular, 0, szBrand.Height);


                    // print the product's price
                    float priceLeft = 0.0f;
                    if (!String.IsNullOrEmpty(photo.OldPrice))
                    {
                        string completeOldPrice = photo.OldPrice + "   ";
                        SizeF szOldPrice = graph.MeasureString(completeOldPrice, fntOldPrice);
                        graph.FillRectangle(brshBackground, priceLeft, tempOrg.Height - szOldPrice.Height, szOldPrice.Width, szOldPrice.Height);
                        graph.DrawString(completeOldPrice, fntOldPrice, brshTextRegular, priceLeft, tempOrg.Height - szOldPrice.Height);
                        priceLeft = szOldPrice.Width;
                    }
                    SizeF szPrice = graph.MeasureString(photo.Price, fntBottom);
                    graph.FillRectangle(brshBackground, priceLeft, tempOrg.Height - szPrice.Height, szPrice.Width, szPrice.Height);
                    graph.DrawString(photo.Price, fntBottom, brshPrice, priceLeft, tempOrg.Height - szPrice.Height);

                    // print the product's SKU
                    string mySku = cfg.Prefix + photo.Sku;
                    SizeF szSKU = graph.MeasureString(mySku, fntBottom);
                    graph.FillRectangle(brshBackground, tempOrg.Width - szSKU.Width, tempOrg.Height - szSKU.Height, szSKU.Width, szSKU.Height);
                    graph.DrawString(mySku, fntBottom, brshTextRegular, tempOrg.Width - szSKU.Width, tempOrg.Height - szSKU.Height);

                    if (photo.Sizes.Count > 0)
                    {
                        String sizeInfo = "Size US: " + String.Join(", ", photo.Sizes.ToArray());
                        using (Bitmap bottom = new Bitmap(tempOrg.Width, 500))
                        using (Graphics bottomGraph = Graphics.FromImage(bottom))
                        {
                            bottomGraph.FillRectangle(brshFillBottom, bottomGraph.ClipBounds);
                            SizeF szSize = bottomGraph.MeasureString(sizeInfo, fntBottom, tempOrg.Width);
                            RectangleF lr = new RectangleF(0, 0, szSize.Width, szSize.Height);
                            bottomGraph.DrawString(sizeInfo, fntBottom, brshTextRegular, lr);

                            using (Bitmap composite = new Bitmap(tempOrg.Width, tempOrg.Height + (int)szSize.Height))
                            using (Graphics compositeGraph = Graphics.FromImage(composite))
                            {
                                compositeGraph.CompositingMode = CompositingMode.SourceCopy;
                                compositeGraph.DrawImageUnscaled(tempOrg, 0, 0);
                                compositeGraph.DrawImageUnscaled(bottom, 0, tempOrg.Height);
                                composite.Save(destinationName, codecInfo, encoderParameters);
                            }
                        }
                    }
                    else
                        tempOrg.Save(destinationName, codecInfo, encoderParameters);
                }
            }
            catch (Exception ex)
            {
                Console.WriteLine("image operation error: " + ex.Message);
                return false;
            }
            return true;
        }

    }
}
