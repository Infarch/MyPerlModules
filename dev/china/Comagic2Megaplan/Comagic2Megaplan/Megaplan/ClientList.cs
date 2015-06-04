using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using RestSharp.Deserializers;

namespace Comagic2Megaplan.Megaplan
{
    class ClientList
    {
        [DeserializeAs(Name = "clients")]
        public List<Client> Clients { get; set; }
    }
}
