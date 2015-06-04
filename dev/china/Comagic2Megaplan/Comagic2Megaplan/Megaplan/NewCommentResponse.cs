using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using RestSharp.Deserializers;

namespace Comagic2Megaplan.Megaplan
{
    class NewCommentResponse
    {
        [DeserializeAs(Name = "comment")]
        public Comment Comment { get; set; }
    }
}
