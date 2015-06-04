using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace FreeSpamerPro
{
    class Interval
    {
        String tag;
        int seconds;

        public int Seconds
        {
            get { return seconds; }
            set { seconds = value; }
        }

        public String Tag
        {
            get { return tag; }
        }

        public Interval(int seconds)
        {
            this.seconds = seconds;
            int m = Convert.ToInt32(seconds / 60);
            int s = seconds - m * 60;
            String format = null;
            if (m > 0)
            {
                if (s > 0)
                {
                    format = "{0} min, {1} sec";
                }
                else
                {
                    format = "{0} min";
                }
            }
            else
            {
                format = "{1} sec";
            }
            tag = String.Format(format, m, s);
        }
    }
}
