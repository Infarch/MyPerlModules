using System;
using System.Net.NetworkInformation;

namespace FreeSpamerPro
{
    class WebTick : ParseTick
    {
        private Action action;

        private bool IsConnected()
        {
            var pinger = new Ping();
            try
            {
                return pinger.Send("free-lance.ru").Status == IPStatus.Success;
            }
            catch (Exception) { return false; }
        }

        public WebTick(Action action)
        {
            this.action = action;
        }

        public override TickResult DoWork()
        {
            if (!IsConnected())
                return TickResult.TryAgain;

            action();

            return TickResult.Ok;
        }
    }
}
