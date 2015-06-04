using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.Linq;
using System.Text;
using System.Windows.Forms;
using System.Collections.Concurrent;
using ShopProcessor.Shops;
using ShopProcessor.CSV;
using System.Threading;
using System.Net;
using System.IO;

using ShopProcessor.UI;

namespace ShopProcessor
{
    public partial class MainForm : Form
    {

        private List<Shop> shoplist;
        private FieldList fieldList = FieldList.GetFields();
        private List<Project> projects;
        
        private Project active_project;
        private Product active_product;

        private String deleted_project_id;

        private ImageList product_images;

        private PhotoQueue download_queue = new PhotoQueue();

        public MainForm()
        {
            InitializeComponent();
        }

        private void MainForm_Load(object sender, EventArgs e)
        {
            try
            {
                // prepare directories
                FileHelper.CheckCreateDirectory(FileHelper.ProjectsDir());

                //init shops
                shoplist = new List<Shop>();
                shoplist.Add(new VYuppoComShop());
                shoplist.Add(new PpSohuComShop());

                // init projects
                projects = (List<Project>)FileHelper.Deserialize(typeof(List<Project>), FileHelper.ProjectsXml());
                if (projects == null)
                {
                    projects = new List<Project>();
                    FileHelper.Serialize(projects, FileHelper.ProjectsXml());
                }
                else
                {
                    // populate download queue
                    foreach (Project proj in projects)
                        foreach (Product prod in proj.Products)
                            foreach (Photo photo in prod.Photos)
                                if (!photo.IsDownloaded) download_queue.Enqueue(photo);
                    ReportQueueSize(download_queue.Count);

                }
                InitOpenProjectMenu();
                downloadWorker.RunWorkerAsync();

            }
            catch (Exception ex)
            {
                MessageBox.Show(ex.Message);
            }
        }

        private void LoadProject(Project p)
        {
            // remove all inputs relate to the previous project
            RemoveInputs();

            active_project = p;
            InitOpenProjectMenu();
            p.LastOpen = DateTime.Now;
            this.Text = "Shop processor: " + p.Title;
            slAppMode.Text = "Edit project";
            projectDeleteMenu.Enabled = true;
            projectEditMenu.Enabled = true;
            tabControl.SelectTab(0);
            btnTake.Enabled = true;
            exportMenu.Enabled = true;
            lbProducts.DataSource = active_project.Products;
            lbProducts.DisplayMember = "Name";
            lbProducts.SelectedIndex = -1;

            // generate inputs for a product's metadata according to the current project preferences
            MakeInputs();

        }

        void RemoveInputs()
        {
            List<Control> clist = new List<Control>();
            foreach (Control c in pnProperties.Controls)
            {
                if (c.Tag != null) clist.Add(c);
            }
            clist.ForEach(x => pnProperties.Controls.Remove(x));
            // clean up the photo view
            viewPhotos.Clear();
        }

        void MakeInputs()
        {
            // expand all active fields to a dictionary
            // in order to avoid spare iterations
            Dictionary<String, Boolean> dic = new Dictionary<String, Boolean>();
            foreach (String id in active_project.FieldIDs)
                dic.Add(id, true);

            int top = viewPhotos.Height + 5;
            int width = pnProperties.Width - 20;

            foreach (Field f in fieldList)
            {
                if (dic.ContainsKey(f.ID))
                {
                    Label l = new Label();
                    l.Text = f.Title;
                    l.Tag = "label-" + f.ID;
                    l.Top = top;
                    l.Width = width;
                    top += l.Height;
                    pnProperties.Controls.Add(l);

                    TextBox tb = new TextBox();
                    tb.Width = width;
                    tb.Top = top;
                    top += tb.Height + 10;
                    tb.Tag = f.ID;
                    tb.Leave += new EventHandler(tb_LostFocus);
                    pnProperties.Controls.Add(tb);

                }

            }

        }

        void tb_LostFocus(object sender, EventArgs e)
        {
            TextBox box = sender as TextBox;
            String id = box.Tag as String;
            if (active_product != null)
                active_product.SetData(id, box.Text);
        }

        private void projectDeleteMenu_Click(object sender, EventArgs e)
        {
            if (Confirm("Do you really want to delete the current project (" + active_project.Title + ")?"))
            {
                DeleteProject(active_project);
                FileHelper.Serialize(projects, FileHelper.ProjectsXml());
            }
        }

        /// <summary>
        /// Removes a project
        /// </summary>
        /// <param name="p"></param>
        private void DeleteProject(Project p)
        {
            tabControl.SelectTab(0);

            lbProducts.DataSource = null;

            deleted_project_id = active_project.ID;
            downloadWorker.RunWorkerCompleted += new RunWorkerCompletedEventHandler(downloadWorker_RunWorkerCompleted);
            downloadWorker.CancelAsync();

            ProjectHelper.DeleteProject(p, FileHelper.ProjectsDir());
            projects.Remove(active_project);
            active_project = null;
            projectDeleteMenu.Enabled = false;
            projectEditMenu.Enabled = false;
            InitOpenProjectMenu();
            this.Text = "Shop processor";
            slAppMode.Text = "Ready";
            
            btnTake.Enabled = false;
            exportMenu.Enabled = false;
            
        }

        void downloadWorker_RunWorkerCompleted(object sender, RunWorkerCompletedEventArgs e)
        {
            // remove photos belong to the active project
            List<Photo> collector = new List<Photo>();

            Photo p = null;
            while (download_queue.TryDequeue(out p))
                if (p.ProjectID != deleted_project_id)
                    collector.Add(p);

            foreach (Photo p1 in collector)
                download_queue.Enqueue(p1);
            
            // clean up the event handler
            downloadWorker.RunWorkerCompleted -= new RunWorkerCompletedEventHandler(downloadWorker_RunWorkerCompleted);

            // start the downloader again
            downloadWorker.RunWorkerAsync();

        }

        /// <summary>
        /// Populates menu by list of existing projects
        /// </summary>
        private void InitOpenProjectMenu()
        {
            // init menu
            projectOpenMenu.DropDownItems.Clear();
            foreach (Project p in projects)
            {
                String text = p.Title + " (" + p.Created.ToString() + ")";
                ToolStripMenuItem mi = new ToolStripMenuItem(text);
                mi.Tag = p;
                if (p == active_project) mi.Enabled = false;
                projectOpenMenu.DropDownItems.Add(mi);
            }
            projectOpenMenu.Enabled = projectOpenMenu.DropDownItems.Count > 0;
        }

        private bool Confirm(string message)
        {
            return MessageBox.Show(message, "Confirm", MessageBoxButtons.YesNo) == DialogResult.Yes;
        }

        private void projectCreateMenu_Click(object sender, EventArgs e)
        {
            NewProjectForm np = new NewProjectForm();
            if (np.ShowDialog(this) == DialogResult.OK)
            {
                String pn = np.ProjectName;
                if (pn == "") pn = "new_project";
                Project project = ProjectHelper.CreateProject(pn, FileHelper.ProjectsDir());
                project.FieldIDs = np.FieldIDs;

                projects.Add(project);
                if (active_project == null) LoadProject(project);
                InitOpenProjectMenu();
            }
        }

        private void MainForm_FormClosing(object sender, FormClosingEventArgs e)
        {
            downloadWorker.CancelAsync();
            FileHelper.Serialize(projects, FileHelper.ProjectsXml());
        }

        private void btnNavigate_Click(object sender, EventArgs e)
        {
            if (tbUrl.Text != "")
            {
                browser.Navigate(tbUrl.Text);
            }
        }

        private void btnTake_Click(object sender, EventArgs e)
        {
            if (browser.Url != null)
            {
                String current_url = browser.Url.ToString();
                
                // search handler
                Shop shop = shoplist.Find(delegate(Shop s) { return s.MatchDomain(current_url); });

                if (shop != null)
                {
                    lbProducts.BeginUpdate();
                    List<Product> prods = shop.ExtractProducts(browser.Document);
                    foreach (Product product in prods)
                    {
                        // add all photos to download queue
                        foreach (Photo photo in product.Photos)
                        {
                            // mark as ACTIVE
                            photo.IsActive = true;
                            if (FileHelper.PhotoDownloaded(FileHelper.ProjectsDir(), active_project, photo))
                            {
                                photo.IsDownloaded = true;
                            }
                            else
                            {
                                photo.ProjectDir = active_project.Directory;
                                photo.ProjectID = active_project.ID;
                                download_queue.Enqueue(photo);
                            }
                        }
                        active_project.Products.Add(product);
                    }

                    lbProducts.SelectedIndex = -1;
                    lbProducts.EndUpdate();
                    ReportQueueSize(download_queue.Count);
                }
                else
                {
                    MessageBox.Show("No handler for " + current_url + ". Contat the software deweloper.");
                }

            }

        }

        private void tabControl_SelectedIndexChanged(object sender, EventArgs e)
        {
            if ((active_project == null) && (tabControl.SelectedTab == tabProducts))
            {
                tabControl.SelectedTab = tabBrowser;
                MessageBox.Show("You must open a project first");
            }
        }

        private void downloadWorker_DoWork(object sender, DoWorkEventArgs e)
        {
            WebClient client = new WebClient();
            BackgroundWorker worker = sender as BackgroundWorker;

            while (!worker.CancellationPending)
            {
                Photo p = null;
                if (download_queue.TryDequeue(out p))
                {
                    try
                    {
                        String path = Path.Combine(FileHelper.ProjectsDir(), p.ProjectDir, p.MD5Hash);
                        client.DownloadFile(p.Url, path);
                        
                        // a check. we will get an exception in case of a bad file
                        Image img = Image.FromFile(path);

                        worker.ReportProgress(download_queue.Count, p);
                    }
                    catch (Exception)
                    {
                        download_queue.Enqueue(p);
                    }

                }
                
                Thread.Sleep(0);
            }
            e.Cancel = true;
        }

        private void btnBack_Click(object sender, EventArgs e)
        {
            if (browser.CanGoBack) browser.GoBack();
        }

        private void projectOpenMenu_DropDownItemClicked(object sender, ToolStripItemClickedEventArgs e)
        {
            Project p = e.ClickedItem.Tag as Project;
            LoadProject(p);
        }

        private void lbProducts_SelectedIndexChanged(object sender, EventArgs e)
        {
            Product prod = lbProducts.SelectedItem as Product;
            if (prod != active_product)
            {
                viewPhotos.Items.Clear();
                product_images = new ImageList();

                active_product = prod;
                if (prod == null)
                {
                    // disable menu
                    productMenu.Enabled = false;
                    // clean up inputs
                    foreach (Control c in pnProperties.Controls)
                    {
                        Type type = c.GetType();
                        if (type == typeof(TextBox))
                            c.Text = "";
                    }
                }
                else
                {
                    // enable menu
                    productMenu.Enabled = true;
                    // prepare images
                    product_images.ImageSize = new Size(50, 50);
                    product_images.Images.Add(ShopProcessor.Properties.Resources.PendingImage);

                    // populate inputs
                    foreach (Control c in pnProperties.Controls)
                    {
                        Type type = c.GetType();
                        if (type == typeof(TextBox))
                        {
                            String id = c.Tag as String;
                            c.Text = prod.GetData(id);
                        }
                    }

                    // create icons
                    foreach (Photo p in prod.Photos)
                    {
                        //Photo p1 = p;
                        ListViewItem item = new PhotoListViewItem(product_images, p, FileHelper.PathToPhoto(FileHelper.ProjectsDir(), active_project, p));
                        viewPhotos.Items.Add(item);
                    }

                    viewPhotos.LargeImageList = product_images;
                }
            }
        }

        private void ReportQueueSize(int size)
        {
            slQueueState.Text = "Photos in queue: " + size;
        }

        private void downloadWorker_ProgressChanged(object sender, ProgressChangedEventArgs e)
        {
            ReportQueueSize(e.ProgressPercentage);
            Photo p = e.UserState as Photo;
            p.IsDownloaded = true;
        }

        private void viewPhotos_ItemChecked(object sender, ItemCheckedEventArgs e)
        {
            PhotoListViewItem item = e.Item as PhotoListViewItem;
            item.PhotoIsActive(item.Checked);
        }

        private void productRenameMenu_Click(object sender, EventArgs e)
        {
            RenameProductForm nf = new RenameProductForm();
            if (nf.ShowDialog(this, active_product.Name) == DialogResult.OK)
            {
                active_product.Name = nf.NewText;
            }
        }

        private void productDeleteMenu_Click(object sender, EventArgs e)
        {
            if (Confirm("You are going to delete the current product. All the products's data will be lost. Continue?"))
            {
                lbProducts.BeginUpdate();
                active_project.Products.Remove(active_product);
                lbProducts.SelectedIndex = -1;
                lbProducts.EndUpdate();
            }
        }

        private void productAbsorbMenu_Click(object sender, EventArgs e)
        {
            AbsorbeProductsForm nf = new AbsorbeProductsForm();
            if (nf.ShowDialog(this, active_project, active_product) == DialogResult.OK)
            {
                Product ap = active_product;

                lbProducts.BeginUpdate();

                foreach (Product prod in nf.CheckedItems)
                {
                    // move photos
                    foreach (Photo p in prod.Photos)
                        active_product.Photos.Add(p);
                    prod.Photos.Clear();

                    // delete the product
                    prod.Data.Clear();
                    active_project.Products.Remove(prod);

                }
                
                lbProducts.EndUpdate();

                lbProducts.SelectedItem = null;
                lbProducts.SelectedItem = ap;

                // save xml
                FileHelper.Serialize(projects, FileHelper.ProjectsXml());
            }

        }

        private void doExportMenu_Click(object sender, EventArgs e)
        {
            lbProducts.Focus();

            ExportForm nf = new ExportForm(active_project);
            nf.ShowDialog();
        }

        private void projectEditMenu_Click(object sender, EventArgs e)
        {
            NewProjectForm np = new NewProjectForm(active_project);
            if (np.ShowDialog(this) == DialogResult.OK)
            {
                this.Text = "Shop processor: " + active_project.Title;
                InitOpenProjectMenu();
                RemoveInputs();
                MakeInputs();
                lbProducts.SelectedIndex = -1;
            }

        }


    }
}
