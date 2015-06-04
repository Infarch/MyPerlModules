using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

using System.Security.Cryptography;
using System.Globalization;
using System.Text.RegularExpressions;

namespace Comagic2Megaplan
{
    /// <summary>
    /// Provides implementation of several PHP functions which works a bit different in c#
    /// </summary>
    class PHP
    {
        /// <summary>
        /// Returns the current datetime value
        /// </summary>
        /// <returns></returns>
        public static string Now()
        {
            return FormatDateTime(DateTime.Now);
        }

        public static string FormatDateTime(DateTime dt)
        {
            string now = dt.ToString("ddd, dd MMM yyyy HH:mm:ss zzz", CultureInfo.InvariantCulture);
            return Regex.Replace(now, "(\\d\\d):(\\d\\d)$", "$1$2");
        }
        /// <summary>
        /// Implements "hash_hmac('sha1', $input, $key, true)"
        /// </summary>
        /// <param name="key"></param>
        /// <param name="input"></param>
        /// <returns></returns>
        public static string HmacSha1(string key, string input)
        {
            byte[] keyBytes = Encoding.UTF8.GetBytes(key);
            using (HMACSHA1 hmacsha1 = new HMACSHA1(keyBytes))
            {
                byte[] hashmessage = hmacsha1.ComputeHash(Encoding.UTF8.GetBytes(input));
                return BytesToHex(hashmessage);
            }
        }


        private static string BytesToHex(byte[] data)
        {
            StringBuilder sBuilder = new StringBuilder();
            for (int i = 0; i < data.Length; i++)
            {
                sBuilder.Append(data[i].ToString("x2"));
            }
            return sBuilder.ToString();
        }

        private static string BytesToString(byte[] data)
        {
            return Encoding.UTF8.GetString(data);
        }

        /// <summary>
        /// Implements "md5($input)"
        /// </summary>
        /// <param name="input"></param>
        /// <returns></returns>
        public static string Md5(string input)
        {
            using (MD5 md5Hash = MD5.Create())
            {
                byte[] data = md5Hash.ComputeHash(Encoding.UTF8.GetBytes(input));
                return BytesToHex(data);
            }
        }

        /// <summary>
        /// Implements "base64_encode($input)"
        /// </summary>
        /// <param name="input"></param>
        /// <returns></returns>
        public static string Base64(string input)
        {
            return Convert.ToBase64String(Encoding.UTF8.GetBytes(input));
        }

        private PHP() { }
    }

}
