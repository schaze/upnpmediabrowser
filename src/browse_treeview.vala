using Gtk;
using Gdk;
using UPNPMediaBrowser;
using UPNPMediaBrowser.Common;
using GUPnP;
using Gee;

namespace UPNPMediaBrowser.UI{
   public enum ItemType{
        CONTAINER,
        AUDIO,
        IMAGE,
        VIDEO,
        PLACEHOLDER
    }

    public enum Column{
        ICON=0,
        NAME,
        DATA
    }

    public class UPNPContentItem : GLib.Object{
        public string               id;
        public int                  child_count;
        public GUPnP.DIDLLiteObject didl;
        public ItemType             item_type;
    }

    public class UPNPResult : GLib.Object{
        public uint starting_index=0;
        public string id;
        public Gtk.TreeIter? iter;

        public UPNPResult(string id, Gtk.TreeIter? iter){
            Object();
            this.id=id;
            this.iter=iter;
            starting_index=0;
        }
    }

    public class UPNPServiceTreeStore : Gtk.TreeStore{
        public const int CHUNK_SIZE = 500;
        public const string UPNPCLASS_AUDIO="object.item.audioItem";
        public const string UPNPCLASS_IMAGE="object.item.imageItem";
        public const string UPNPCLASS_VIDEO="object.item.videoItem";


        private static Gdk.Pixbuf container_icon;
        private static Gdk.Pixbuf audio_icon;
        private static Gdk.Pixbuf image_icon;
        private static Gdk.Pixbuf video_icon;
        private static Gdk.Pixbuf placeholder_icon;

        private UPNPDevice device;

        construct{
            container_icon=get_icon(Gtk.Stock.DIRECTORY);
            audio_icon=get_icon("audio-x-generic");
            image_icon=get_icon("image-x-generic");
            video_icon=get_icon("video-x-generic");
            placeholder_icon=get_icon(Gtk.Stock.REFRESH);
        }


        public UPNPServiceTreeStore(UPNPDevice device, int columns, ...){
            Type[] types=new Type[columns];
            var varargs=va_list();
            for(int i=0; i<columns; i++){
                types[i]=varargs.arg();
            }
            set_column_types(types);
            this.device=device;
        }

        public void load_items(Gtk.TreePath? path){
            Gtk.TreeIter? iter=null;
            string ID="0";
            UPNPContentItem parent_item=null;
            if (path != null){
                get_iter(out iter, path);
                get(iter,Column.DATA, out parent_item);
                ID=parent_item.id;
            }
            // check if this node is already loaded
            Gtk.TreeIter child;
            if (iter_children(out child, iter)){
                UPNPContentItem item;
                get(child,Column.DATA, out item);
                if (item.item_type!=ItemType.PLACEHOLDER || item.child_count > -1)
                    return;
                item.child_count=0;
            }
            UPNPResult result=new UPNPResult(ID,iter);
            //load items
            start_load_items(result);
        }


        private void start_load_items(UPNPResult result) {
            device.ContentDirectory.begin_action(
                    "Browse",
                    (proxy,action)=>{
                        complete_load_items(result, proxy,action);
                    },
                    "ObjectID", typeof (string), result.id,
                    "BrowseFlag", typeof (string), "BrowseDirectChildren",
                    "Filter", typeof (string), "*",
                    "StartingIndex", typeof (uint), result.starting_index,
                    "RequestedCount", typeof (uint), CHUNK_SIZE,
                    "SortCriteria", typeof (string), "");
        }

        private  void complete_load_items(UPNPResult result, GUPnP.ServiceProxy proxy, GUPnP.ServiceProxyAction action) {
            string DIDL_result;
            uint count;
            uint total;

            try {
                proxy.end_action(action,
                        "Result", typeof (string), out DIDL_result,
                        "NumberReturned", typeof (uint), out count,
                        "TotalMatches", typeof (uint), out total
                        );

                if (count > 0){
                    GUPnP.DIDLLiteParser parser = new GUPnP.DIDLLiteParser ();
                    parser.container_available.connect (
                            (parser,item) =>
                            {
                                on_container_available(result,parser,item);
                            });
                    parser.item_available.connect (
                            (parser,item) =>
                            {
                                on_item_available(result,parser,item);
                            });
                    try {
                        parser.parse_didl (DIDL_result);
                    } catch (Error err) {
                        warning ("error parsing didl results: %s", err.message);
                    }
                }
                if ((result.starting_index+count) >= total){
                    // Done loading, remove the placeholder
                    Gtk.TreeIter child;
                    if (iter_children(out child, result.iter)){
                        UPNPContentItem item;
                        get(child,Column.DATA, out item);
                        if (item.item_type==ItemType.PLACEHOLDER)
                            remove(ref child);
                    }
                }else{
                    // Still items to load, start at new index again
                    result.starting_index+=count;
                    start_load_items(result);
                }
            }catch(Error e){
                debug ("Error fetching MetaData: %s %d", e.message, e.code);
            }
        }

        public void on_container_available(UPNPResult result,GUPnP.DIDLLiteParser parser, GUPnP.DIDLLiteContainer item){
            Gtk.TreeIter item_iter;
            append(out item_iter,result.iter);
            var data_item=new UPNPContentItem();
            data_item.id=item.id;
      //      data_item.upnp_class = item.upnp_class;
            data_item.child_count=item.child_count;
       //     data_item.udn=device.Device.udn;
        //    data_item.service_path="";
            data_item.item_type=ItemType.CONTAINER;
            data_item.didl=item;

            set(item_iter,
                    Column.ICON,        container_icon,
                    Column.NAME,        item.title,
                    Column.DATA,        data_item);

            Gtk.TreeIter loading_iter;
            append(out loading_iter, item_iter);
            var placeholder_item=new UPNPContentItem();
            placeholder_item.id="";
          //  placeholder_item.upnp_class = "placeholder";
            placeholder_item.child_count=-1;
         //   placeholder_item.udn="";
         //   placeholder_item.service_path="";
            placeholder_item.item_type=ItemType.PLACEHOLDER;
            placeholder_item.didl=null;

            set (loading_iter,
                    Column.ICON,        placeholder_icon,
                    Column.NAME,        "...loading...",
                    Column.DATA,        placeholder_item);

        }

        public void on_item_available(UPNPResult result, GUPnP.DIDLLiteParser parser, GUPnP.DIDLLiteItem item){
            Gtk.TreeIter item_iter;
            append(out item_iter,result.iter);
            Gdk.Pixbuf icon=null;
            ItemType item_type=ItemType.VIDEO;
            if (item.upnp_class.has_prefix(UPNPCLASS_AUDIO)){
                icon=audio_icon;
                item_type=ItemType.AUDIO;
            }
            else if (item.upnp_class.has_prefix(UPNPCLASS_IMAGE))
            {
                icon=image_icon;
                item_type=ItemType.IMAGE;
            }
            else if (item.upnp_class.has_prefix(UPNPCLASS_VIDEO))
            {
                icon=video_icon;
                item_type=ItemType.VIDEO;
            }

            var data_item=new UPNPContentItem();
            data_item.id=item.id;
            //data_item.upnp_class = item.upnp_class;
            data_item.child_count=-1;
            //data_item.udn=device.Device.udn;
            //data_item.service_path="";
            data_item.item_type=item_type;
            data_item.didl=item;

            set(item_iter,
                    Column.ICON,        icon,
                    Column.NAME,        item.title,
                    Column.DATA,        data_item);
        }
    }



   [GtkTemplate (ui = "/schaze/upnpmediabrowser/ui/browsetreeview.ui")]
    public class BrowseTreeView : Gtk.TreeView{
        public const int CHUNK_SIZE = 500;
        private HashMap<UPNPDevice,UPNPServiceTreeStore> stores;
        private UPNPDevice device;

        private static Gdk.Pixbuf placeholder_icon;

        construct{
            placeholder_icon=get_icon(Gtk.Stock.REFRESH);
        }

        public BrowseTreeView(UPNPMediaBrowser.Application app, Context ctxt){
            Object ();
            this.device=null;
            this.stores=new HashMap<UPNPDevice,UPNPServiceTreeStore>();
            init_widgets();
        }

        private void init_widgets(){
            var column=new TreeViewColumn();
            column.title=_("Content");

            var renderer = new CellRendererPixbuf();
            column.pack_start(renderer, false);
            column.add_attribute(renderer, "pixbuf", Column.ICON);

            var textRenderer = new CellRendererText();
            column.pack_start(textRenderer, true);
            column.add_attribute(textRenderer, "text", Column.NAME);

            append_column(column);
        }

        public void load_media_server(UPNPDevice device){
            this.device=device;
            if (!stores.has_key(device)){
                UPNPServiceTreeStore store = new UPNPServiceTreeStore(device,9,
                        typeof(Gdk.Pixbuf), // Column.ICON
                        typeof(string),     // Column.NAME
                        typeof(UPNPContentItem));       // Column.DATA
                stores[device]=store;
                set_model(store);

                Gtk.TreeIter loading_iter;
                store.append(out loading_iter, null);
                var placeholder_item=new UPNPContentItem();
                placeholder_item.id="";
               // placeholder_item.upnp_class = "placeholder";
                placeholder_item.child_count=-1;
               // placeholder_item.udn="";
               // placeholder_item.service_path="";
                placeholder_item.item_type=ItemType.PLACEHOLDER;
                placeholder_item.didl=null;

                store.set (loading_iter,
                        Column.ICON,        placeholder_icon,
                        Column.NAME,        "...loading...",
                        Column.DATA,        placeholder_item);

                store.load_items(null);
           }else {
               set_model(stores[device]);
           }
        }

        public void media_server_removed(ServiceProxy proxy){
        
        }

        [GtkCallback]
        private void on_row_activated(Gtk.TreePath path, Gtk.TreeViewColumn column){
            Gtk.TreeIter? iter=null;
            UPNPContentItem item=null;
            if (path != null){
                stores[device].get_iter(out iter, path);
                stores[device].get(iter,Column.DATA, out item);
                print("Item selected: %s\n",item.didl.title);
                GLib.List<GUPnP.DIDLLiteResource> resources=item.didl.get_resources();
                if (resources.length()>0){
                    GLib.Settings settings=new GLib.Settings ("org.schaze.upnpmediabrowser.general");
                    AppInfo player;
                    if (settings.get_boolean("use-default-mediaplayer")){
                        player=AppInfo.get_default_for_type("video/mp4",true);
                    }else{
                        player=AppInfo.create_from_commandline(
                                settings.get_string("mediaplayer-commandline"),
                                settings.get_string("mediaplayer-name"),
                                0);
                    }
                    GLib.List<string> uris=new GLib.List<string>();
                    uris.append(resources.first().data.uri);
                    player.launch_uris(uris,null);
                }
            }
        }

        [GtkCallback]
        private void on_row_expanded(Gtk.TreeIter iter, Gtk.TreePath path){
            stores[device].load_items(path);
        }
    }
}
