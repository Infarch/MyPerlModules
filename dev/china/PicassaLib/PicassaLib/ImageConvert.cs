using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Drawing;
using System.Drawing.Drawing2D;

namespace PicassaLib
{
    public class ImageConvert
    {
        public static void MakeSmallThumbnail(Image image, String filename)
        {
            Image img = ResizeImage(image, 200, 150);
            img.Save(filename);
        }

        public static void MakeLargeThumbnail(Image image, String filename)
        {
            Image img = ResizeImageWidth(image, 300);
            img.Save(filename);
        }

        public static Image ResizeImageWidth(Image imgToResize, int width)
        {
            int sourceWidth = imgToResize.Width;
            int sourceHeight = imgToResize.Height;

            float nPercent = 0;
            if (sourceWidth > width)
            {
                nPercent = ((float)width / (float)sourceWidth);
            }

            int destWidth = (int)(sourceWidth * nPercent);
            int destHeight = (int)(sourceHeight * nPercent);

            return DoResize(imgToResize, destWidth, destHeight);
        }

        public static Image ResizeImage(Image imgToResize, int width, int height)
        {
            int sourceWidth = imgToResize.Width;
            int sourceHeight = imgToResize.Height;

            float nPercent = 0;
            float nPercentW = 0;
            float nPercentH = 0;

            nPercentW = ((float)width / (float)sourceWidth);
            nPercentH = ((float)height / (float)sourceHeight);

            if (nPercentH < nPercentW)
                nPercent = nPercentH;
            else
                nPercent = nPercentW;

            int destWidth = (int)(sourceWidth * nPercent);
            int destHeight = (int)(sourceHeight * nPercent);

            return DoResize(imgToResize, destWidth, destHeight);
        }

        private static Image DoResize(Image img, int destWidth, int destHeight)
        {
            Bitmap b = new Bitmap(destWidth, destHeight);
            Graphics g = Graphics.FromImage((Image)b);
            g.InterpolationMode = InterpolationMode.HighQualityBicubic;

            g.DrawImage(img, 0, 0, destWidth, destHeight);
            g.Dispose();

            return (Image)b;

        }
    }
}
