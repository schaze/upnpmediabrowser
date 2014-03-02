using Config;
using Gtk;
using UPNPMediaBrowser;
using GUPnP;

namespace UPNPMediaBrowser.UI{
    [GtkTemplate (ui = "/schaze/upnpmediabrowser/ui/window.ui")]
    public class Window: Gtk.ApplicationWindow{
        public static Window instance;

#if !USE_HEADERBAR
        [GtkChild]
        private Gtk.Box toolbar_container;
#endif 

        [GtkChild]
        private Gtk.ScrolledWindow devices_treeview_container;

        [GtkChild]
        private Gtk.ScrolledWindow browse_treeview_container;

        private Context context;

        private UPNPMediaBrowser.UI.MediaRendererToolbar toolbar;
        private UPNPMediaBrowser.UI.DevicesTreeView devices_treeview;
        private UPNPMediaBrowser.UI.BrowseTreeView browse_treeview;

        public Window (UPNPMediaBrowser.Application app){
            Object (application: app);
            Window.instance=this;

            try {
              context = new Context (null, null, 0);
            } catch (Error err) {
              critical (err.message);
              return;
            }
            try {
                Gdk.Pixbuf app_icon=new Gdk.Pixbuf.from_resource("/schaze/upnpmediabrowser/icons/upnpmediabrowser.svg");
                icon_name=null;
                set_icon(app_icon);
            }catch (Error e){
                warning("Cannot load application icon from ressources!\n%s",e.message);
            
            }

            toolbar=new UPNPMediaBrowser.UI.MediaRendererToolbar(app,context);

#if USE_HEADERBAR
            print ("USING HEADERBAR\n");
                set_default_size(800,600);
                Gtk.HeaderBar headerBar = new Gtk.HeaderBar();
                headerBar.set_show_close_button (true);

                toolbar.remove(toolbar.start_box);
                toolbar.remove(toolbar.title_box);
                toolbar.remove(toolbar.end_box);

                headerBar.pack_start(toolbar.start_box);
                headerBar.set_custom_title (toolbar.title_box);
                headerBar.custom_title.set_hexpand(true);
                headerBar.pack_end(toolbar.end_box);

                //headerBar.set_title("Test 123");
                headerBar.show ();
                set_titlebar (headerBar);
#else
                print ("NOT ---- USING HEADERBAR\n");
                toolbar_container.add(toolbar);
                toolbar_container.reorder_child(toolbar,0);
#endif 

            devices_treeview=new UPNPMediaBrowser.UI.DevicesTreeView(app,context);
            devices_treeview_container.add(devices_treeview);

            browse_treeview=new UPNPMediaBrowser.UI.BrowseTreeView(app,context);
            browse_treeview_container.add(browse_treeview);

            toolbar.rescanRequest.connect(()=>{
                    devices_treeview.rescanDevices();
                    });

            devices_treeview.on_device_selected.connect((device)=>{
                   browse_treeview.load_media_server(device); 
                    });

        }
    }
}
