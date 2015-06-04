using System.Collections.Concurrent;

namespace ShopProcessor
{
    public class PhotoQueue : ConcurrentQueue<Photo>
    {
    }
}
