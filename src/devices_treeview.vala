using Gtk;
using Gdk;
using UPNPMediaBrowser;
using UPNPMediaBrowser.Common;
using GUPnP;

namespace UPNPMediaBrowser.UI{
    [GtkTemplate (ui = "/schaze/upnpmediabrowser/ui/devicestreeview.ui")]
    public class DevicesTreeView: Gtk.TreeView{
        public signal void on_device_selected(UPNPDevice device);

        private ControlPoint cp;
        private ListStore store;
        private Gtk.TreeSelection selection;

        public DevicesTreeView(UPNPMediaBrowser.Application app, Context ctxt){
            Object ();
            initWidgets();
            initControlPoint(ctxt);
        }

        private void initControlPoint(Context ctxt){
            cp = new ControlPoint(ctxt,"ssdp:all");
            cp.device_proxy_available.connect (on_device_proxy_available);
            cp.device_proxy_unavailable.connect (on_device_proxy_unavailable);
            cp.active = true;
        }

        private void initWidgets(){
            store=new ListStore(3,
                    typeof(Gdk.Pixbuf),
                    typeof(string),
                    typeof(UPNPDevice));
            set_model(store);

            var column=new TreeViewColumn();
            column.title="MediaServers";

            var renderer = new CellRendererPixbuf();
            column.pack_start(renderer, false);
            column.add_attribute(renderer, "pixbuf", Column.ICON);

            var textRenderer = new CellRendererText();
            column.pack_start(textRenderer, true);
            column.add_attribute(textRenderer, "text", Column.NAME);

            append_column(column);
            selection=get_selection();
            selection.set_mode(SelectionMode.SINGLE);
            selection.changed.connect(on_selection_changed);
        }

        private void on_device_proxy_available (ControlPoint cp,
                DeviceProxy proxy) {
            UPNPDevice device=new UPNPDevice(proxy);
            if (device.has_content_directory){
                print("Adding: %s [%s]\n",device.Name, device.Device.udn);
                load_device_icon.begin(proxy,48,48,(obj,res) => {
                    Pixbuf icon=load_device_icon.end(res);
                    Gtk.TreeIter iter;
                    store.append(out iter);
                    store.set (iter,
                        Column.ICON     , icon,
                        Column.NAME     , device.Name,
                        Column.DATA     , device);
                });
            }
        }
        private void on_device_proxy_unavailable (ControlPoint cp,
                DeviceProxy proxy) {
            print("Device removed: %s\n",proxy.udn);
            store.foreach((model, path, iter) => {
                    UPNPDevice device;
                    store.get(iter,Column.DATA,out device);
                    if (device !=null && device.compare_to(proxy)){
                        store.remove(iter);
                        //return true;
                    }
                    return false;
            });

        }
        private async Gdk.Pixbuf load_device_icon(DeviceProxy device, int width, int height){
            string mime;
            int depth,owidth,oheight;
            string url=device.get_icon_url(null,-1,-1,-1, true, out mime, out depth, out owidth, out oheight);
            return yield download_image(url,width,height);
        }

        public void on_selection_changed(){
            Gtk.TreeModel model;
            Gtk.TreeIter iter;
            if (selection.get_selected(out model, out iter)){
                UPNPDevice device;
                model.get(iter, Column.DATA, out device);
                print("Device Selected! %s\n",device.Device.udn);
                on_device_selected(device);
            }
        }


        public void rescanDevices(){
            print("performing rescan\n");
            cp.rescan();

        }

    }
}
