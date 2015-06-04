
namespace FreeSpamerPro
{
    public enum TickResult { Ok, TryAgain };
    abstract class ParseTick
    {
        private string tag;

        public string Tag
        {
            get { return tag; }
            set { tag = value; }
        }

        public abstract TickResult DoWork();
    }
}
