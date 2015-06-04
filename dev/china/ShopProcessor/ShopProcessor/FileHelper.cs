using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

using System.IO;
using System.Xml.Serialization;

namespace ShopProcessor
{
    public class FileHelper
    {
        private static String projects_xml = "projects.xml";
        private static String output_csv = "output.csv";
        private static String fields_xml = "fields.xml";

        /// <summary>
        /// Returns full path to a folder containing projects data
        /// </summary>
        /// <returns></returns>
        public static String ProjectsDir()
        {
            return Path.Combine(System.AppDomain.CurrentDomain.BaseDirectory, "projects");
        }

        /// <summary>
        /// Returns full path to a xml file containing fields definitions
        /// </summary>
        /// <returns></returns>
        public static String FieldsXml()
        {
            return Path.Combine(ProjectsDir(), fields_xml);
        }

        /// <summary>
        /// Returns full path to a xml file containing projects definitions
        /// </summary>
        /// <returns></returns>
        public static String ProjectsXml()
        {
            return Path.Combine(ProjectsDir(), projects_xml);
        }

        /// <summary>
        /// Returns full path to a folder with output files
        /// </summary>
        /// <returns></returns>
        public static String OutputDir()
        {
            return Path.Combine(System.AppDomain.CurrentDomain.BaseDirectory, "output");
        }

        /// <summary>
        /// Returns full path to a scv file containing esported data.
        /// </summary>
        /// <returns></returns>
        public static String OutputCSV(){
            return Path.Combine(OutputDir(), output_csv);
        }

        /// <summary>
        /// Returns full path to a folder with converted pictures
        /// </summary>
        /// <returns></returns>
        public static String OutputPicturesDir()
        {
            return Path.Combine(OutputDir(), "products_pictures");
        }

        /// <summary>
        /// Cleans up output folders
        /// </summary>
        public static void PrepareOutput()
        {
            if (!Directory.Exists(OutputDir())) Directory.CreateDirectory(OutputDir());
            if (File.Exists(OutputCSV())) File.Delete(OutputCSV());
            if (Directory.Exists(OutputPicturesDir()))
            {
                DirectoryInfo di = new DirectoryInfo(OutputPicturesDir());
                foreach (System.IO.FileInfo file in di.GetFiles()) file.Delete();
            }
            else
            {
                Directory.CreateDirectory(OutputPicturesDir());
            }
        }

        /// <summary>
        /// Returns path to a photo file.
        /// </summary>
        /// <param name="proj"></param>
        /// <param name="photo"></param>
        /// <returns></returns>
        public static String PathToPhoto(Project proj, Photo photo)
        {
            return Path.Combine(PathToProject(proj), photo.MD5Hash);
        }

        /// <summary>
        /// Returns full path to an output picture file.
        /// </summary>
        /// <param name="filename"></param>
        /// <returns></returns>
        public static String PathToOutputPhoto(String filename)
        {
            return Path.Combine(OutputPicturesDir(), filename);
        }

        /// <summary>
        /// Checks existence of the specified directory, creates it if not exist
        /// </summary>
        /// <param name="dir"></param>
        public static void CheckCreateDirectory(string dir)
        {
            if (!Directory.Exists(dir))
            {
                Directory.CreateDirectory(dir);
            }
        }

        /// <summary>
        /// Performs serialization of the specified object to xml file
        /// </summary>
        /// <param name="type"></param>
        /// <param name="obj"></param>
        /// <param name="filename"></param>
        public static void Serialize(Object obj, String filename)
        {
            XmlSerializer sr = new XmlSerializer(obj.GetType());
            StreamWriter writer = new StreamWriter(filename);
            sr.Serialize(writer, obj);
            writer.Close();
        }

        /// <summary>
        /// Performs deserialization of the specified xml file
        /// </summary>
        /// <param name="type"></param>
        /// <param name="filename"></param>
        /// <returns></returns>
        public static Object Deserialize(Type type, String filename)
        {
            Object obj = null;
            if (File.Exists(filename))
            {
                XmlSerializer sr = new XmlSerializer(type);
                FileStream stream = new FileStream(filename, FileMode.Open);
                obj = sr.Deserialize(stream);
                stream.Close();
            }
            return obj;
        }

        /// <summary>
        /// The function tries to create directory "1" under the specified root directory.
        /// If there already is that directory then try to create "2", etc...
        /// Returns name of a created directory
        /// </summary>
        /// <param name="rootdir"></param>
        /// <returns></returns>
        public static String CreateSecondDirectory(String rootdir)
        {
            String dir = "1";
            int index = 1;
            while (Directory.Exists(Path.Combine(rootdir, dir)))
            {
                index++;
                dir = index.ToString();
            }
            Directory.CreateDirectory(Path.Combine(rootdir, dir));
            return dir;
        }

        /// <summary>
        /// Deletes the specified directory completely including all contents
        /// </summary>
        /// <param name="path"></param>
        public static void DeleteDirectory(String path)
        {
            Directory.Delete(path);
            //DirectoryInfo di = new DirectoryInfo(path);
            //foreach (System.IO.FileInfo file in di.GetFiles()) file.Delete();
            //foreach (System.IO.DirectoryInfo subDirectory in directory.GetDirectories()) directory.Delete(true);
        }

        public static String PathToProject(Project project)
        {
            return Path.Combine(ProjectsDir(), project.Directory);
        }

        public static String PathToPhoto(String root, Photo photo)
        {
            return Path.Combine(root, photo.MD5Hash);
        }

        public static String PathToPhoto(String root, Project project, Photo photo)
        {
            return Path.Combine(root, project.Directory, photo.MD5Hash);
        }

        public static Boolean PhotoDownloaded(String root, Project project, Photo photo)
        {
            return File.Exists(PathToPhoto(root, project, photo));
        }

    }
}
