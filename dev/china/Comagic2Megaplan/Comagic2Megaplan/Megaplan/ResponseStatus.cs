using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using RestSharp.Deserializers;

namespace Comagic2Megaplan.Megaplan
{
    class ResponseStatus
    {
        [DeserializeAs(Name = "code")]
        public string Code { get; set; }

        [DeserializeAs(Name = "message")]
        public string Message { get; set; }
    }
}
