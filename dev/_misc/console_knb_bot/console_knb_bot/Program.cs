using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.IO;
using System.Net;
using System.Text.RegularExpressions;
using System.Threading;

namespace console_knb_bot
{
    enum GameResult {Undefined, Win, Defeat, Nobody};

    class Program
    {
        //static string username = "irismishka";
        //static string password = "6981327paloma";
        //static float initialOffer = 0.1f;

        static string username;
        static string password;
        static float initialOfferPercent;

        Random rnd = new Random();
        float currentOffer = 0f;

        public float CurrentOffer
        {
            get { return currentOffer; }
        }

        CookieCollection cookies;

        static void Main(string[] args)
        {
            if (args.Length < 3)
            {
                Console.WriteLine("Usage console_knb_bot.exe username password initial_offer_percent");
                return;
            }
            
            // read arguments
            username = args[0];
            password = args[1];
            initialOfferPercent = (float)Double.Parse(args[2].Replace('.', ','));

            //LetsRock();
            LetsTest();

        }

        private static void LetsTest()
        {
            Program p = new Program();
            float currentOffer = initialOfferPercent;
            bool as_percent = true;
            if (p.Login())
            {
                Console.WriteLine("Login success");
                // create a game
                string gameId = p.MakeGame(currentOffer, as_percent);
                if (String.IsNullOrEmpty(gameId))
                {
                    Console.WriteLine("No game id");
                }
                else
                {
                    GameResult r = p.WaitGame(gameId);
                }
            }
            else
            {
                throw new Exception("Login failed");
            }

        }

        private static void LetsRock()
        {
            Program p = new Program();
            float currentOffer = initialOfferPercent;
            bool as_percent = true;
            //int limit = 10;
            Console.WriteLine("Performing login as " + username);
            if (p.Login())
            {
                Console.WriteLine("Login success");
                while (true)
                {

                    string gameId = p.MakeGame(currentOffer, as_percent);
                    if (String.IsNullOrEmpty(gameId)) break;
                    Console.WriteLine("Created game " + gameId);

                    // wait result
                    GameResult r = p.WaitGame(gameId);
                    switch (r)
                    {
                        case GameResult.Defeat:
                            currentOffer = p.currentOffer * 2.3f;
                            as_percent = false;
                            break;
                        case GameResult.Nobody:
                            currentOffer = p.CurrentOffer * 1.1f;
                            as_percent = false;
                            break;
                        case GameResult.Win:
                            currentOffer = initialOfferPercent;
                            as_percent = true;
                            break;
                    }
                    //if (limit-- == 0) break;
                }
            }
            else
            {
                Console.WriteLine("Login failed");
            }

        }

        private GameResult WaitGame(string gameId)
        {
            

            Console.WriteLine("Start checking game "+gameId);
            GameResult r = GameResult.Undefined;
            //string pattern = String.Format("<td class=\"td\" align=\"center\">{0}</td>(.+?</tr>)", gameId);
            while (r == GameResult.Undefined)
            {
                int pause = rnd.Next(3, 13);
                Console.WriteLine("Wait {0} seconds", pause);
                Thread.Sleep(pause * 1000);

                string postdata = String.Format("games_list={0}", gameId);
                string pageText = DoPost("http://fortunatime.com/index.php?mod=gamezone&mod2=game_knb&sub=momento&com=check_actuality", postdata);

                Console.WriteLine("Fetched: " + pageText);
                // parse list of games
                //Match game = Regex.Match(pageText, pattern, RegexOptions.Singleline);
                //if (!game.Success)
                //{
                //   throw new Exception("No Game");
                //}
                //string gameinfo = game.Groups[1].Value;

                // if game info inclides "<script>" then the game is not finished yet
                //if (!Regex.IsMatch(gameinfo, "<script"))
                //{
                //    // we have some result, get the winner
                //    Match winner = Regex.Match(gameinfo, "<td class=\"td\" align=\"center\">([^<]+)</td>[^<]*</tr>");
                //    if (!winner.Success) throw new Exception("No Winner info");
                //    string win_login = winner.Groups[1].Value;
                //    if (win_login.Equals("-"))
                //    {
                //        r = GameResult.Nobody;
                //        Console.WriteLine("No winner in this game");
                //    }
                //    else if (win_login.Equals(username))
                //    {
                //        r = GameResult.Win;
                //        Console.WriteLine("You win");
                //    }
                //    else
                //    {
                //        r = GameResult.Defeat;
                //        Console.WriteLine("{0} win", win_login);
                //    }
                //}
            }
            return r;
        }

        private string MakeGame(float offer, bool as_percent)
        {
            String pageText = DoGet("http://fortunatime.com/knb/play");

            // get ballance
            float ballance = 0f;
            Match mb = Regex.Match(pageText, "<div class=\"account_fonds\">На счету:\\s+<span class=\"blue\">(\\d+,\\d+)</span> руб.</div>");
            if (mb.Success)
            {
                ballance = (float)Double.Parse(mb.Groups[1].Value.Replace('.', ','));
            }
            else
                throw new Exception("No ballance");

            if (as_percent) offer *= ballance;

            if (offer < 0.01f)
            {
                Console.WriteLine("Too low offer: upgraded to 0.01");
                offer = 0.01f;
            }

            if (ballance < offer) throw new Exception("No enough money!");

            currentOffer = offer;

            Console.WriteLine("Creating a game (stake: {0})", offer);

            // create game
            string postdata = String.Format("x=123&game_sum={0}&game_type=4&game_with=all&opponent=", offer).Replace(',', '.');
            pageText = DoPost("http://fortunatime.com/index.php?mod=gamezone&mod2=game_knb&sub=momento&com=create_game", postdata);
            if (!Regex.IsMatch(pageText, "\"response\":\"OK\""))
            {
                throw new Exception("Creating of a game failed");
            }

            // get list of games
            pageText = DoGet("http://fortunatime.com/index.php?mod=gamezone&mod2=game_knb&sub=momento&com=gamelist&is_all=0&min=NaN&max=NaN");
            // clean up the text
            pageText = CleanUpResponse(pageText);
            // get my latest game id
            string pattern = String.Format("id=\"game_id_hidden\" value=\"(\\d+)\" alt=\"1\" />\\s*<li class=\"rows1\"><font[^>]+>[^<]+</font></li><li class=\"rows2\">{0}", username);
            MatchCollection ids = Regex.Matches(pageText, pattern);
            string id = String.Empty;
            foreach (Match m in ids)
            {
                id = m.Groups[1].Value;
            }


            Console.WriteLine("Games!" + id);

            //http://fortunatime.com/index.php?mod=gamezone&mod2=game_knb&sub=momento&com=check_actuality
            //games_list=3095453%2C3095452%2C3095454%2C3095438%2C3095455%2C3095456

            return id;
        }

        private string CleanUpResponse(string pageText)
        {
            string str = Regex.Replace(pageText, @"\\r|\\t|\\n", "");
            str = Regex.Replace(str, @"\\", "");

            return str;
        }

        private string DoPost(string url, string postdata)
        {
            HttpWebRequest request = PrepareRequest(url);
            request.Method = "POST";
            ASCIIEncoding encoding = new ASCIIEncoding();
            byte[] data = encoding.GetBytes(postdata);
            request.ContentLength = data.Length;
            Stream newStream = request.GetRequestStream();
            // Send the data.
            newStream.Write(data, 0, data.Length);
            newStream.Close();
            return ProcessResponse(request);
        }

        private string DoGet(string url)
        {
            HttpWebRequest request = PrepareRequest(url);
            request.Method = "GET";
            return ProcessResponse(request);
        }

        private HttpWebRequest PrepareRequest(string url)
        {
            HttpWebRequest request = (HttpWebRequest)WebRequest.Create(url);
            request.AllowAutoRedirect = false;
            request.CookieContainer = new CookieContainer();
            if (cookies != null) request.CookieContainer.Add(cookies);
            request.Accept = "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8";
            request.UserAgent = "Mozilla/5.0 (Windows NT 6.1; WOW64; rv:11.0) Gecko/20100101 Firefox/11.0";
            request.ContentType = "application/x-www-form-urlencoded";
            request.Referer = "http://fortunatime.com/";
            request.Host = "fortunatime.com";
            return request;
        }

        private string ProcessResponse(HttpWebRequest request)
        {
            HttpWebResponse response = (HttpWebResponse)request.GetResponse();
            String pageText;
            using (TextReader reader = new StreamReader(response.GetResponseStream(), Encoding.GetEncoding("windows-1251")))
            {
                pageText = reader.ReadToEnd();
            }
            response.Close();
            if (cookies == null) cookies = response.Cookies;
            return pageText;
        }

        private bool Login()
        {
            string postData = "login_submit=%CE%F2%EF%F0%E0%E2%E8%F2%FC&user=" + username + "&pass=" + password;
            String pageText = DoPost("http://fortunatime.com/users/login", postData);
            // check login state
            //return Regex.IsMatch(pageText, "<a href=\"http://fortunatime.com/users/logout\">Выход</a>");
            return pageText.Equals(String.Empty);
        }
    }
}
