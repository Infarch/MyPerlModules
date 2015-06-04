using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using RestSharp;

namespace Comagic2Megaplan.Comagic
{
    class Api
    {
        const string BaseUrl = "http://api.comagic.ru/api";

        public string SessionKey { get; private set; }

        public Api(string username, string password)
        {
            SessionKey = GetLogin(username, password).session_key;
            if (String.IsNullOrEmpty(SessionKey)) throw new ApplicationException("Comagic login failed");
        }

        public T Execute<T>(RestRequest request) where T : new()
        {
            var client = new RestClient(BaseUrl);
            var response = client.Execute<ResponseWrapper<T>>(request);

            //Console.WriteLine(response.Content);

            if (response.ErrorException != null)
            {
                const string message = "Error retrieving response.  Check inner details for more info.";
                var comagicException = new ApplicationException(message, response.ErrorException);
                throw comagicException;
            }

            var wrapper = response.Data;

            if (!wrapper.Success)
                throw new ApplicationException("Operation failed: " + wrapper.Message);

            if (wrapper.Data == null)
            {
                throw new ApplicationException("Data is null");
            }

            return wrapper.Data;
        }

        public Login GetLogin(string login, string password)
        {
            var request = new RestRequest();
            request.Resource = "login/";
            request.AddParameter("login", login);
            request.AddParameter("password", password);

            return Execute<Login>(request);
        }

        public void Logout()
        {
            var client = new RestClient(BaseUrl);
            var request = new RestRequest();
            request.Resource = "logout/";
            request.AddParameter("session_key", SessionKey);
            client.Execute(request);
        }

        private string FormatDate(DateTime date)
        {
            return date.ToString("yyyy-MM-dd H:mm:ss");
        }

        public List<Call> GetCalls(DateTime from, DateTime till)
        {
            var request = new RestRequest();
            request.Resource = "v1/call/";
            request.AddParameter("session_key", SessionKey);
            request.AddParameter("date_from", FormatDate(from));
            request.AddParameter("date_till", FormatDate(till));

            return Execute<List<Call>>(request);
        }

    }
}
