using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using RestSharp.Deserializers;

namespace Comagic2Megaplan.Comagic
{
    class ResponseWrapper<T> where T : new()
    {
        [DeserializeAs(Name = "success")]
        public bool Success { get; set; }

        [DeserializeAs(Name = "message")]
        public string Message { get; set; }

        [DeserializeAs(Name = "data")]
        public T Data { get; set; }
    }
}
