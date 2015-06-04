using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Net;

using ParseLib.Database;

namespace ParseLib.Classes
{
    //public enum MemberStatus { New = 1, InProgress = 2, Done = 3, Failed = 4 }

    public interface IParseMember
    {

        int Id { get; set; }
        string Url { get; set; }
        int Errors { get; set; }
        int Status { get; set; }

        void MarkNew();
        void MarkDone();
        void MarkFailed();

        /// <summary>
        /// Revert all changes, get weight of the given exception, update erorr counter.
        /// In case when the counter is greater than error limit make the member 'failed'.
        /// </summary>
        /// <param name="exc">The exception to be discovered</param>
        //void RegisterException(ParserEntities context, Exception exc);

        /// <summary>
        /// The main function. Processes the member.
        /// </summary>
        void Process();

        //void Process(ParserEntities context, string content);

        //void Process(ParserEntities context, byte[] data);

        /// <summary>
        /// Return members which are not processed yet.
        /// </summary>
        /// <returns></returns>
       // IParseMember[] GetUnprocessedMembers(ParserEntities context);

    }

    public static class ParseMemberExtension
    {

        public static void MarkNew(this IParseMember member)
        {
            member.Status = (int)MemberStatus.New;
        }
        public static void MarkDone(this IParseMember member)
        {
            member.Status = (int)MemberStatus.Done;
        }
        public static void MarkFailed(this IParseMember member)
        {
            member.Status = (int)MemberStatus.Failed;
        }

        //public static void RegisterException(this IParseMember member, ParserEntities context, Exception exc)
        //{
            
            
        //    // ****************************
        //    // TODO: reload the member!!!!!
        //    // ****************************



        //    int weight = 0;
        //    if (exc is WebException)
        //    {
        //        // low level exception
        //        weight = 3;
        //    }
        //    else
        //    {
        //        throw new Exception("Re-opened exception", exc);
        //    }
        //    member.Errors += weight;
        //    if (member.Errors > 15)
        //    {
        //        member.MarkFailed();
        //    }
        //    else
        //    {
        //        member.MarkNew();
        //    }

        //}
        //public static void Process(this IParseMember member)
        //{
        //    try
        //    {
        //        using (ParserEntities context = new ParserEntities())
        //        {
        //            member.MarkDone();
        //            HttpWebRequest request = (HttpWebRequest)WebRequest.Create(member.Url);
        //            request.Headers.Add("Accept-Encoding", "gzip, deflate");
        //            HttpWebResponse response = (HttpWebResponse)request.GetResponse();

        //        }
        //    }
        //    catch (Exception exc)
        //    {
        //        using (ParserEntities context = new ParserEntities())
        //        {
        //            member.RegisterException(context, exc);
        //            context.SaveChanges();
        //        }
        //    }
        //}

    }

}
