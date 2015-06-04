using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

using System.Runtime.InteropServices;
using System.Windows.Forms;
//using System.Text.RegularExpressions;

namespace ChampsSportsHelper
{
    partial class Form1
    {
        const int WM_DRAWCLIPBOARD = 0x308;
        const int WM_CHANGECBCHAIN = 0x030D;

        //private static Regex reSports = new Regex("^http://www\\.champssports\\.com/product/model:\\d+/sku:");
        //private static Regex reModels = new Regex("^E3F920DF-E1E6-4A94-827C-C10BF3ECBEAB:(.+)$");

        [DllImport("User32.dll")]
        protected static extern int
                  SetClipboardViewer(int hWndNewViewer);

        [DllImport("User32.dll", CharSet = CharSet.Auto)]
        public static extern bool
               ChangeClipboardChain(IntPtr hWndRemove,
                                    IntPtr hWndNewNext);

        [DllImport("user32.dll", CharSet = CharSet.Auto)]
        public static extern int SendMessage(IntPtr hwnd, int wMsg,
                                             IntPtr wParam,
                                             IntPtr lParam);

        IntPtr nextClipboardViewer;

        protected override void WndProc(ref System.Windows.Forms.Message m)
        {
            switch (m.Msg)
            {
                case WM_DRAWCLIPBOARD:
                    ProcessClipboardData();
                    SendMessage(nextClipboardViewer, m.Msg, m.WParam,
                                m.LParam);
                    break;

                case WM_CHANGECBCHAIN:
                    if (m.WParam == nextClipboardViewer)
                        nextClipboardViewer = m.LParam;
                    else
                        SendMessage(nextClipboardViewer, m.Msg, m.WParam,
                                    m.LParam);
                    break;

                default:
                    base.WndProc(ref m);
                    break;
            }
        }

        private void ProcessClipboardData()
        {
            if (!Monitoring || !Clipboard.ContainsText()) return;
            string text = Clipboard.GetText();

            var models = RX.ExtractModels(text);
            foreach (var model in models)
            {
                if (mc.TryAdd(model))
                    SiteProcessor.ProcessModelAsync(model);
            }

        }

    }
}
