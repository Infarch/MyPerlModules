using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

using RestSharp.Deserializers;

namespace Comagic2Megaplan.Megaplan
{
    class DealList
    {
        [DeserializeAs(Name = "deals")]
        public List<Deal> Deals { get; set; }
    }
}
