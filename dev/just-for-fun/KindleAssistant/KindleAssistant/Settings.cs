using System;
using System.Collections.Generic;
using System.Text;
using System.Xml.Serialization;
using System.IO;
using System.Security.Cryptography;


namespace KindleAssistant
{
    [XmlRoot("settings")]
    public class Settings : Dictionary<String, String>, IXmlSerializable
    {

        public static String Profile = "default";

        # region Save / Load

        private static byte[] GetBytes()
        {
            return ASCIIEncoding.ASCII.GetBytes("qldyHe5C");
        }

        private static String GetFileName()
        {
            return "isoft.kindle.assistant." + Profile;
        }

        public static Settings Load()
        {

            String path = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData), GetFileName());
            Settings obj = null;
            if (File.Exists(path))
            {
                try
                {
                    
                    DESCryptoServiceProvider cryptoProvider = new DESCryptoServiceProvider();
                    FileStream stream = File.Open(path, FileMode.Open);

                    CryptoStream csDecrypt = new CryptoStream(
                        stream,
                        cryptoProvider.CreateDecryptor(GetBytes(), GetBytes()),
                        CryptoStreamMode.Read);
                    XmlSerializer sr = new XmlSerializer(typeof(Settings));
                    Object x = sr.Deserialize(csDecrypt);
                    obj = (Settings)x;
                    csDecrypt.Close();
                    stream.Close();

                }
                catch { }
            }
            return obj;

        }

        public static void Save(Settings obj)
        {
            String path = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData), GetFileName());
            try
            {
                DESCryptoServiceProvider cryptoProvider = new DESCryptoServiceProvider();

                FileStream stream = File.Open(path, FileMode.Create);
                CryptoStream cryp = new CryptoStream(
                    stream,
                    cryptoProvider.CreateEncryptor(GetBytes(), GetBytes()),
                    CryptoStreamMode.Write);
                StreamWriter writer = new StreamWriter(cryp);
                XmlSerializer sr = new XmlSerializer(obj.GetType());
                sr.Serialize(writer, obj);
                writer.Close();
                cryp.Close();
                stream.Close();

            }
            catch { }

        }


        # endregion


        #region IXmlSerializable Members

        public System.Xml.Schema.XmlSchema GetSchema()
        {
            return null;
        }

        public void ReadXml(System.Xml.XmlReader reader)
        {
            XmlSerializer keySerializer = new XmlSerializer(typeof(String));
            XmlSerializer valueSerializer = new XmlSerializer(typeof(String));

            bool wasEmpty = reader.IsEmptyElement;
            reader.Read();
            if (wasEmpty)
                return;

            while (reader.NodeType != System.Xml.XmlNodeType.EndElement)
            {
                reader.ReadStartElement("item");
                reader.ReadStartElement("key");
                String key = (String)keySerializer.Deserialize(reader);
                reader.ReadEndElement();
                reader.ReadStartElement("value");
                String value = (String)valueSerializer.Deserialize(reader);
                reader.ReadEndElement();
                this.Add(key, value);
                reader.ReadEndElement();
                reader.MoveToContent();
            }
            reader.ReadEndElement();
        }



        public void WriteXml(System.Xml.XmlWriter writer)
        {
            XmlSerializer keySerializer = new XmlSerializer(typeof(String));
            XmlSerializer valueSerializer = new XmlSerializer(typeof(String));
            foreach (String key in this.Keys)
            {
                writer.WriteStartElement("item");
                writer.WriteStartElement("key");
                keySerializer.Serialize(writer, key);
                writer.WriteEndElement();
                writer.WriteStartElement("value");
                String value = this[key];
                valueSerializer.Serialize(writer, value);
                writer.WriteEndElement();
                writer.WriteEndElement();
            }
        }

        #endregion


    }

}
