using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using RestSharp.Deserializers;

namespace Comagic2Megaplan.Megaplan
{
    class ResponseWrapper<T> where T : new()
    {
        [DeserializeAs(Name = "status")]
        public ResponseStatus Status { get; set; }

        [DeserializeAs(Name = "data")]
        public T Data { get; set; }
    }
}
