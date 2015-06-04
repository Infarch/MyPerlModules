using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

using RestSharp;
using RestSharp.Deserializers;
using System.IO;

namespace Comagic2Megaplan.Megaplan
{
    class Api
    {
        string Host { get; set; }
        string BaseUrl { get; set; }

        const string ContentType = "application/x-www-form-urlencoded";

        private Dictionary<string, string> Places;

        Login Login { get; set; }

        public Api(string userHost, string username, string password)
        {
            Host = userHost + ".megaplan.ru";
            BaseUrl = "https://" + Host;

            Places = new Dictionary<string, string>();
            Places.Add("74952563977", "Eventmoskva");
            Places.Add("74952043043", "Eventmoskva");
            Places.Add("74952368740", "Eventmoskva");
            Places.Add("74952563119", "Eventmoskva");
            Places.Add("74952563644", "Eventmoskva");
            Places.Add("74952561812", "Eventmoskva");
            Places.Add("74952563557", "Eventmoskva");
            Places.Add("74952563044", "Eventmoskva");
            Places.Add("74952563686", "Eventmoskva");
            Places.Add("74952563441", "Eventmoskva");
            Places.Add("74952563909", "Eventmoskva");
            Places.Add("74952560398", "Eventmoskva");
            Places.Add("74952563039", "Eventmoskva");
            Places.Add("74952563192", "Eventmoskva");

            Places.Add("74951250829", "Известия холл");

            Places.Add("74952563001", "Icon");

            Login = GetLogin(username, PHP.Md5(password));
        }

        public T Execute<T>(RestRequest request) where T : new()
        {
            var client = new RestClient(BaseUrl);
            
            var response = client.Execute<ResponseWrapper<T>>(request);

            if (response.ErrorException != null)
            {
                const string message = "Error retrieving response.  Check inner details for more info.";
                var exception = new ApplicationException(message, response.ErrorException);
                throw exception;
            }

            var wrapper = response.Data;
            var status = wrapper.Status;

            if (status == null)
            {
                throw new ApplicationException("Status is null");
            }

            if (status.Code != "ok")
                throw new ApplicationException("Operation failed: " + status.Message);

            if (wrapper.Data == null)
            {
                throw new ApplicationException("Data is null");
            }

            return wrapper.Data;
        }

        private Login GetLogin(string login, string passwordMd5)
        {
            var request = new RestRequest();
            request.Resource = "/BumsCommonApiV01/User/authorize.api";
            request.AddParameter("Login", login);
            request.AddParameter("Password", passwordMd5);
            return Execute<Login>(request);

        }

        private string GetXAuthHeader(string signature)
        {
            string sha1 = PHP.HmacSha1(Login.SecretKey, signature);
            var b64 = PHP.Base64(sha1);
            return Login.AccessId + ":" + b64;
        }
        
        private void SignRequest(RestRequest request)
        {
            string requestDate = PHP.Now();

            string ctype = "";
            if (request.Method == Method.POST)
            {
                ctype = ContentType;
                request.AddHeader("Content-Type", ctype);
            }

            string signhost = Host + request.Resource;
            string signature = string.Join(
                "\u000a",
                new string [] { 
                    request.Method.ToString(), "", ctype, requestDate, signhost 
                }
            );

            string xAutHeader = GetXAuthHeader(signature);

            request.AddHeader("Accept", "application/json");
            request.AddHeader("X-Sdf-Date", requestDate);
            request.AddHeader("X-Authorization", xAutHeader);
        }

        /// <summary>
        /// Brings together the resource name and the given parameters.
        /// We need the function for signed GET requests
        /// </summary>
        /// <param name="resource"></param>
        /// <param name="uriParams"></param>
        /// <returns></returns>
        private string BuildUri(string resource, Dictionary<string,string>uriParams)
        {
            StringBuilder sb = new StringBuilder(resource);
            if (uriParams.Count > 0)
            {
                sb.Append('?');
                var xx = uriParams.Select(x => x.Key + "=" + Uri.EscapeDataString(x.Value));
                sb.Append(string.Join("&", xx));
            }
            return sb.ToString();
        }

        /// <summary>
        /// Returns either the Client found or null
        /// </summary>
        /// <param name="phone"></param>
        /// <returns></returns>
        public Client FindClientFirstOrDefault(string phone)
        {
            var list = FindClients(phone, 1);
            return list.Count > 0 ? list[0] : default(Client);
        }

        public List<Client> FindClients(string phone, int limit)
        {
            string resource = "/BumsCrmApiV01/Contractor/list.api";

            var request = new RestRequest();
            request.Method = Method.POST;
            request.Resource = resource;
            request.AddParameter("FilterId", "all");
            request.AddParameter("Limit", limit);
            request.AddParameter("Phone", phone);

            SignRequest(request);

            var cl = Execute<ClientList>(request);

            return cl.Clients;
        }

        public Deal FindDealFirstOrDefault(int clientId)
        {
            var list = FindDeals(clientId, 1);
            return list.Count > 0 ? list[0] : default(Deal);
        }

        public List<Deal> FindDeals(int clientId, int limit)
        {
            var request = new RestRequest();
            request.Method = Method.POST;
            request.Resource = "/BumsTradeApiV01/Deal/list.api";
            request.AddParameter("FilterFields[Contractor]", clientId);
            request.AddParameter("Limit", limit);

            SignRequest(request);

            var dl = Execute<DealList>(request);

            return dl.Deals;
        }

        public Comment CreateComment(string subjectType, int subjectId, string text, FileInfo attachment)
        {
            var request = new RestRequest();
            request.Method = Method.POST;
            request.Resource = "/BumsCommonApiV01/Comment/create.api";

            request.AddParameter("SubjectType", subjectType);
            request.AddParameter("SubjectId", subjectId);
            request.AddParameter("Model[Text]", text);

            if (attachment != null)
            {
                request.AddParameter("Model[Attaches][0][Name]", attachment.Name);

                StringBuilder sb = new StringBuilder();
                using (Stream s = attachment.OpenRead())
                {
                    const int amount = 3000;
                    byte[] data = new byte[amount];

                    long bytesLeft = s.Length;

                    while (bytesLeft > 0)
                    {
                        int blockSize = bytesLeft > amount ? amount : (int)bytesLeft;
                        s.Read(data, 0, blockSize);
                        bytesLeft -= blockSize;
                        sb.Append(Convert.ToBase64String(data, 0, blockSize));
                    }
                }

                request.AddParameter("Model[Attaches][0][Content]", sb.ToString());

            }

            SignRequest(request);

            var cr = Execute<NewCommentResponse>(request);
            return cr.Comment;
        }

        public Deal CreateDeal(int clientId, int? acId, string description, string phoneTo, DateTime callDate, int waitTime, int duration)
        {

            var request = new RestRequest();
            request.Method = Method.POST;
            request.Resource = "/BumsTradeApiV01/Deal/save.api";

            string plo = Places.ContainsKey(phoneTo) ? Places[phoneTo] : "";

            string dateStr = callDate.ToString("yyyy-MM-dd HH:mm:ss");

            // cannot be upper than 500 due to Megaplan API limitation
            if (duration > 500) duration = 500;

            request.AddParameter("ProgramId", 3);
            request.AddParameter("StatusId", 11);
            request.AddParameter("StrictLogic", 0);

            request.AddParameter("Model[Contractor]", clientId);
            request.AddParameter("Model[Description]", description);
            request.AddParameter(Config.Megaplan.Fields.PhoneTo, phoneTo);
            request.AddParameter(Config.Megaplan.Fields.WaitTime, waitTime);
            request.AddParameter(Config.Megaplan.Fields.Duration, duration);
            request.AddParameter(Config.Megaplan.Fields.AcId, acId);
            request.AddParameter(Config.Megaplan.Fields.CallDate, dateStr);
            request.AddParameter(Config.Megaplan.Fields.Place, plo);

            SignRequest(request);

            var dr = Execute<NewDealResponse>(request);

            return dr.Deal;
        }

        private bool IsDigitsOnly(string str)
        {
            foreach (char c in str)
            {
                if (c < '0' || c > '9')
                    return false;
            }

            return true;
        }

        private string ReplacePhone(string phone)
        {
            if (phone.Length < 10)
                throw new Exception("The phone numer [" + phone + "] is too short");
            if (!IsDigitsOnly(phone))
                throw new Exception("The phone numer [" + phone + "] is wrong");

            StringBuilder sb = new StringBuilder("ph_m-");
            sb.Append(phone.Substring(0, 1)).Append('-').Append(phone.Substring(1, 3)).Append('-').Append(phone.Substring(4)).Append("\u0009");
            return sb.ToString();
        }

        public Client CreateClient(string phone)
        {
            var request = new RestRequest();
            request.Method = Method.POST;
            request.Resource = "/BumsCrmApiV01/Contractor/save.api";
            request.AddParameter("Model[TypePerson]", "human");
            request.AddParameter("Model[FirstName]", "Контакт из Comagic (cm2mp)");
            request.AddParameter("Model[LastName]", " ");
            request.AddParameter("Model[MiddleName]", " ");
            request.AddParameter("Model[Responsibles]", Config.Megaplan.ResponsibleId);
            request.AddParameter("Model[Phones][0]", ReplacePhone(phone));
            SignRequest(request);
            var result = Execute<NewClientResponse>(request);
            return result.Client;
        }

    }
}
