using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace ShopProcessor
{
    public class ProjectHelper
    {
        /// <summary>
        /// Creates a new project with complete file structure
        /// </summary>
        /// <param name="name"></param>
        /// <param name="rootdir"></param>
        /// <returns></returns>
        public static Project CreateProject(String name, String rootdir)
        {
            Project p = new Project();
            p.Title = name;
            p.Directory = FileHelper.CreateSecondDirectory(rootdir);
            p.Created = DateTime.Now;

            return p;
        }


        /// <summary>
        /// Removes all the project's contents from hdd
        /// </summary>
        /// <param name="project"></param>
        /// <param name="rootdir"></param>
        public static void DeleteProject(Project project, String rootdir)
        {

        }
    }
}
