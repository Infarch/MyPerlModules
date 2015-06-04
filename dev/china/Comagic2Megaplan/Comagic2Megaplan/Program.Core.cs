using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading;
using System.IO;

namespace Comagic2Megaplan
{
    partial class Program
    {

        private void Worker(int intervalMinutes)
        {
            TimeSpan standardInterval = TimeSpan.FromMinutes(intervalMinutes);
            TimeSpan beforeNow = TimeSpan.FromMinutes(10);
            TimeSpan aSecond = TimeSpan.FromSeconds(1);

            DateTime readFrom = Config.LastTime;
            if (readFrom.Year == 1)
            {
                LogWriter.Debug("Considered as the first run");

                // there is no date. consider the situation as the first run.
                // the lastReadDate value must be Now - <standardInterval>.
                readFrom = Utc2Moskow(DateTime.UtcNow - standardInterval - beforeNow);
            }


            while (true)
            {
                DateTime readTill = Utc2Moskow(DateTime.UtcNow - beforeNow);
                if (readTill <= readFrom)
                {
                    LogWriter.Info(String.Format("Interval {0} - {1} is not valid. Please wait for the next run.", readFrom, readTill));
                }
                else
                {
                    try
                    {
                        readFrom = TransferCalls(readFrom, readTill) + aSecond;

                        Config.LastTime = readFrom;
                    }
                    catch (Exception ex)
                    {
                        LogWriter.Error("Working cycle failed", ex);
                    }
                }

                LogWriter.Info(String.Format("Waiting {0} minute(s) before the next run.", intervalMinutes));
                Thread.Sleep(standardInterval);
            }
        }

        private DateTime TransferCalls(DateTime readFrom, DateTime readTill)
        {
            string megaLogin = Config.Megaplan.Login;
            string megaPassword = Config.Megaplan.Password;
            string megaHost = Config.Megaplan.Host;

            List<Comagic.Call> calls = GetComagicCalls(readFrom, readTill, true);
            
            if (calls.Count > 0)
            {
                LogWriter.Info(String.Format("Performing login to Megaplan as '{0}'", megaLogin));

                Megaplan.Api megaApi = new Megaplan.Api(megaHost, megaLogin, megaPassword);

                DateTime lastSuccessCall = readFrom - TimeSpan.FromSeconds(1);

                foreach (var call in calls)
                {
                    try
                    {
                        if (call.CallDate.Year == 1)
                            throw new Exception("Call time is wrong: " + call.CallDate);

                        CreateClientDeal(megaApi, call);

                        // next time, read calls AFTER the call
                        lastSuccessCall = call.CallDate;
                    }
                    catch (Exception e)
                    {
                        LogWriter.Error("Error processing a call", e);
                        return lastSuccessCall;
                    }
                }
            }

            return readTill;
        }

        private static List<Comagic.Call> GetComagicCalls(DateTime readFrom, DateTime readTill, bool doFiltering)
        {
            string cmLogin = Config.Comagic.Login;
            string cmPassword = Config.Comagic.Password;

            LogWriter.Info(String.Format("Performing login to Comagic as '{0}'", cmLogin));

            Comagic.Api cmApi = new Comagic.Api(cmLogin, cmPassword);

            LogWriter.Info(String.Format("Fetching calls between {0} and {1} (Moskow)", readFrom, readTill));

            List<Comagic.Call> calls = cmApi.GetCalls(readFrom, readTill);
            cmApi.Logout();

            LogWriter.Info(String.Format("{0} call(s) total", calls.Count));

            List<Comagic.Call> workList = new List<Comagic.Call>();
            foreach (var call in calls)
            {
                if (Config.NotForMegaplan(call.ToNumber))
                {
                    LogWriter.Info(String.Format("Звонок на номер {0} не для мегаплана", call.ToNumber));
                }
                else
                {
                    workList.Add(call);
                }
            }

            // sort by date to be sure 100% that the order is correct
            workList.Sort(delegate(Comagic.Call x, Comagic.Call y)
            {
                return x.CallDate.CompareTo(y.CallDate);
            });

            return workList;
        }

        private void CreateClientDeal(Megaplan.Api api, Comagic.Call call)
        {
            LogWriter.Info(String.Format("Processing a call (Id: {0}, From: {1}, To: {2}, At: {3})", call.Id, call.FromNumber, call.ToNumber, call.CallDate));

            string numberFrom = call.FromNumber;
            LogWriter.Info(String.Format("Searching a client: {0}", numberFrom));
            Megaplan.Client client = api.FindClientFirstOrDefault(numberFrom);

            if (client == default(Megaplan.Client))
            {
                LogWriter.Info("Client does not exist. Start creating a new one.");
                client = api.CreateClient(numberFrom);
                LogWriter.Info(String.Format("A new client has been created (Megaplan Id: {0})", client.Id));
            }
            else
            {
                LogWriter.Info(String.Format("Client exists (Megaplan Id: {0})", client.Id));
            }

            // create a deal
            LogWriter.Info("Creating a deal");

            string dealDescription = " ";// "Звонок от клиента из comagic.ru";

            StringBuilder sb = new StringBuilder("Время звонка: ");
            sb.Append(call.CallDate.ToString("yyyy-MM-dd HH:mm:ss")).Append("\n");
            if (call.IsLost())
            {
                sb.Append("Звонок пропущен");
            }
            else
            {
                sb.Append("Время ожидания: ").Append(call.WaitTime).Append("\n").Append("Продолжительность разговора: ").Append(call.Duration);
            }
            string commentText = sb.ToString();

            // check whether the call has been recorded, download the file if so
            FileInfo localFileInfo = null;
            if (call.FileLinks.Count > 0)
            {
                //TmpDirName
                string fLink = call.FileLinks[0];
                LogWriter.Info(String.Format("Downloading: {0}", fLink));
                string localFile = Web.DownloadFileHttp("http:" + fLink, TmpDirName);
                localFileInfo = new FileInfo(localFile);
                LogWriter.Info("Download done");
            }

            var deal = api.CreateDeal(client.Id, call.AcId, dealDescription, call.ToNumber, call.CallDate, call.WaitTime, call.Duration);
            LogWriter.Info(String.Format("Created a deal: https://{0}.megaplan.ru/deals/{1}/card/", Config.Megaplan.Host, deal.Id));

            LogWriter.Info(String.Format("Creating a comment (deal Id: {0})", deal.Id));

            api.CreateComment("deal", deal.Id, commentText, localFileInfo);

            try
            {
                if (localFileInfo != null) localFileInfo.Delete(); ;
            }
            catch (Exception e)
            {
                LogWriter.Error("Cannot delete a temporary file", e);
            }
        }


    }
}
