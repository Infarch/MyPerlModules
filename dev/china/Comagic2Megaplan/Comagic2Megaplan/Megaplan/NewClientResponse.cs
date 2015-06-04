using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using RestSharp.Deserializers;

namespace Comagic2Megaplan.Megaplan
{
    class NewClientResponse
    {
        [DeserializeAs(Name = "contractor")]
        public Client Client { get; set; }
    }
}
