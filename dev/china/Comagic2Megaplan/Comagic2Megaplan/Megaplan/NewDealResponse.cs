using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using RestSharp.Deserializers;

namespace Comagic2Megaplan.Megaplan
{
    class NewDealResponse
    {
        [DeserializeAs(Name = "deal")]
        public Deal Deal { get; set; }
    }
}