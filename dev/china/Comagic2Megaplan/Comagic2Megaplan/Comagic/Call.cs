using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using RestSharp.Deserializers;

namespace Comagic2Megaplan.Comagic
{
    

    class Call
    {
        [DeserializeAs(Name = "id")]
        public int Id { get; set; }

        [DeserializeAs(Name = "numa")]
        public string FromNumber { get; set; }

        [DeserializeAs(Name = "numb")]
        public string ToNumber { get; set; }

        [DeserializeAs(Name = "call_date")]
        public DateTime CallDate { get; set; }

        [DeserializeAs(Name = "status")]
        public string Status { get; set; }

        [DeserializeAs(Name = "wait_time")]
        public int WaitTime { get; set; }

        [DeserializeAs(Name = "duration")]
        public int Duration { get; set; }

        [DeserializeAs(Name = "ac_id")]
        public int AcId { get; set; }

        [DeserializeAs(Name = "file_link")]
        public List<string> FileLinks { get; set; }

        public bool IsLost()
        {
            return !string.IsNullOrEmpty(Status) && Status == "lost";
        }

    }
}
