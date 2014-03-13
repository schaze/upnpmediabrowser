using Gtk;
using UPNPMediaBrowser;
using UPNPMediaBrowser.Common;
using GUPnP;
using Gdk;


namespace UPNPMediaBrowser.UI{

    [GtkTemplate (ui = "/schaze/upnpmediabrowser/ui/toolbar_box.ui")]
    public class MediaRendererToolbar: Gtk.Box{
        public const string TRANSPORT_STATE_STOPPED="STOPPED";
        public const string TRANSPORT_STATE_PLAYING="PLAYING";
        public const string TRANSPORT_STATE_TRANSITIONING="TRANSITIONING";
        public const string TRANSPORT_STATE_PAUSED_PLAYBACK="PAUSED_PLAYBACK";
        public const string TRANSPORT_STATE_PAUSED_RECORDING="PAUSED_RECORDING";
        public const string TRANSPORT_STATE_RECORDING="RECORDING";
        public const string TRANSPORT_STATE_NO_MEDIA_PRESENT="NO_MEDIA_PRESENT";

            // Play, Stop, Pause, Seek, Next, Previous
        public const string TRANSPORT_ACTION_PLAY="Play";
        public const string TRANSPORT_ACTION_STOP="Stop";
        public const string TRANSPORT_ACTION_PAUSE="Pause";
        public const string TRANSPORT_ACTION_SEEK="Seek";
        public const string TRANSPORT_ACTION_NEXT="Next";
        public const string TRANSPORT_ACTION_PREVIOUS="Previous";

        UPNPMediaBrowser.Application app;

        Gdk.Pixbuf local_renderer_icon=get_icon("go-home",24);

        public signal void rescanRequest ();

        [GtkChild]
        public Gtk.Box start_box;
        [GtkChild]
        public Gtk.Box title_box;
        [GtkChild]
        public Gtk.Box end_box;

        [GtkChild]
        private Gtk.ComboBox media_renderers;

        [GtkChild]
        private Gtk.Scale position_info;
        [GtkChild]
        private Gtk.Label abs_time_label;
        [GtkChild]
        private Gtk.Label duration_label;
        [GtkChild]
        public Gtk.Label title;

        [GtkChild]
        private Gtk.VolumeButton volume_button;

        [GtkChild]
        private Gtk.Image icon_play;
        [GtkChild]
        private Gtk.Image icon_pause;

        [GtkChild]
        private Gtk.Button play_pause_button;
        [GtkChild]
        private Gtk.Button stop_button;
        [GtkChild]
        private Gtk.Button next_button;
        [GtkChild]
        private Gtk.Button previous_button;

        private ControlPoint cp;
        private Gtk.ListStore store;
        private UPNPDevice active_device=null;
        private string current_transport_state=TRANSPORT_STATE_STOPPED;

        private GLib.TimeoutSource update_timer=null;

        private int volume=-1;

        public MediaRendererToolbar(UPNPMediaBrowser.Application app,Context ctxt){
            Object ();
            this.app=app;
            initWidgets();
            initControlPoint(ctxt);
        }

        private void initControlPoint(Context ctxt){
            cp = new ControlPoint(ctxt,"ssdp:all");
            cp.device_proxy_available.connect (on_device_proxy_available);
            cp.service_proxy_available.connect (on_service_proxy_available);
            cp.device_proxy_unavailable.connect (on_device_proxy_unavailable);
            cp.active = true;
        }


        private void initWidgets(){
            store=new ListStore(3,
                    typeof(Gdk.Pixbuf),
                    typeof(string),
                    typeof(GLib.Object));
            media_renderers.set_model(store);

            var renderer = new CellRendererPixbuf();
            media_renderers.pack_start(renderer, false);
            media_renderers.add_attribute(renderer, "pixbuf", Column.ICON);

            var textRenderer = new CellRendererText();
            media_renderers.pack_start(textRenderer, true);
            media_renderers.add_attribute(textRenderer, "text", Column.NAME);
            Gtk.TreeIter iter;
            store.append(out iter);
            store.set (iter,
                Column.ICON     , local_renderer_icon,
                Column.NAME     , "Local",
                Column.DATA  , null);
            media_renderers.set_active(0);
        }

        private void on_service_proxy_available (ControlPoint cp, ServiceProxy proxy){
            print("Service: %s\n",proxy.service_type);
        }

        private void on_device_proxy_available (ControlPoint cp,
                DeviceProxy proxy) {
            UPNPDevice device=new UPNPDevice(proxy);
            if (device.has_rendering_control){
                print("ADD DEVICE\n");
                load_device_icon.begin(device,24,0,(obj,res) => {
                print("Downloaded Icon\n");
                    Pixbuf icon=load_device_icon.end(res);
                    Gtk.TreeIter iter;
                    store.append(out iter);
                    store.set (iter,
                        Column.ICON     , icon,
                        Column.NAME     , device.Name,
                        Column.DATA  , device);
                });
            }
        }

        private void on_device_proxy_unavailable (ControlPoint cp,
                DeviceProxy proxy) {
            store.foreach((model, path, iter) => {
                    UPNPDevice device;
                    store.get(iter,Column.DATA,out device);
                    if (device !=null && device.compare_to(proxy)){
                        store.remove(iter);
                        return true;
                    }
                    return false;
            });

        }
        private async Gdk.Pixbuf load_device_icon(UPNPDevice device, int width, int height){
            string mime;
            int depth,owidth,oheight;
            string url=device.Device.get_icon_url(null,-1,-1,-1, true, out mime, out depth, out owidth, out oheight);
            return yield download_image(url,width,height);
        }

        [GtkCallback]
        private void on_rescanbutton_clicked () {
            print("Rescan button clicked\n");
            rescanRequest();
        }

        [GtkCallback]
        private void open_settings () {
            var settings_dialog=new SettingsDialog(app);
            settings_dialog.modal=true;
            settings_dialog.show();
        }

        [GtkCallback]
        private void ControlPointComboBox_changed(){
            Gtk.TreeIter iter;
            media_renderers.get_active_iter(out iter);
            string name;
            store.get(iter, Column.NAME, out name);
            UPNPDevice device;
            store.get(iter, Column.DATA, out device);
            print ("Selected mediarenderer: %s\n",name);
            subscribe_to_mediarenderer(device);
        }

        [GtkCallback]
        private void play_pause_button_clicked_cb () {
            if (active_device == null)
                return;
            if (current_transport_state==TRANSPORT_STATE_PLAYING){
                active_device.AVTransport.begin_action(
                    "Pause",
                    (proxy,action)=>{
                        string result="";
                        proxy.end_action(action, null
                        );
                    },
                    "InstanceID", typeof (string), "0"
                );
            }else{
                active_device.AVTransport.begin_action(
                    "Play",
                    (proxy,action)=>{
                        string result="";
                        proxy.end_action(action, null
                        );
                    },
                    "InstanceID", typeof (string), "0",
                    "Speed", typeof (string), "1"
                );
            }
        }

        [GtkCallback]
        private void stop_button_clicked_cb() {
            if (active_device == null)
                return;
            active_device.AVTransport.begin_action(
                "Stop",
                (proxy,action)=>{
                    string result="";
                    proxy.end_action(action, null
                    );
                },
                "InstanceID", typeof (string), "0"
            );
        }
        public void on_mediarenderer_notify(ServiceProxy proxy, string variable, Value val){
            print("[%s]=%s\n",variable, (string)val);
            if(variable=="LastChange"){
                GUPnP.LastChangeParser lc_parser=new GUPnP.LastChangeParser();

                on_mute_changed(lc_parser,val);
                on_volume_changed(lc_parser, val);
                on_track_duration_changed(lc_parser,val);
                on_transport_state_changed(lc_parser,val);
                on_transport_actions_changed(lc_parser,val);
                on_track_metadata_changed(lc_parser,val);

            }
        }

        private void on_volume_changed(GUPnP.LastChangeParser lc_parser, Value val){
            print ("on_volume_changed\n");
            int tmp_volume=-1;
            try {
                if(lc_parser.parse_last_change(0,val as string,"Volume",typeof(int),out tmp_volume) && tmp_volume != -1) {
                    volume=tmp_volume;
                    print ("setting volume button value to %i\n",tmp_volume);
                    print ("volume button %f\n",volume_button.value);
                    volume_button.value=tmp_volume;
                    print ("setting volume button value DONE\n");
                }
                print ("Volume: %i\n",tmp_volume);
            } catch (Error err) {
                warning ("error parsing didl results: %s", err.message);
            }
        }

        private void on_mute_changed(GUPnP.LastChangeParser lc_parser, Value val){
            print ("on_mute_changed\n");
            bool muted=volume<0;
            bool changed=false;
            bool muted_false=false;
            try{
                if(lc_parser.parse_last_change(0,val as string,"Mute",typeof(bool),out muted_false) && muted_false){
                    muted=true;
                    changed=true;
                }

                bool muted_true=true;
                if(lc_parser.parse_last_change(0,val as string,"Mute",typeof(bool),out muted_true) && !muted_true){
                    muted=false;
                    changed=true;
                }
            } catch (Error err) {
                warning ("error parsing didl results: %s", err.message);
            }

            if (changed)
                if (muted)
                    volume_button.value=-1;
                else
                    volume_button.value=volume;
        }

        private void on_track_duration_changed(GUPnP.LastChangeParser lc_parser, Value val){
            string current_track_duration=null;
            try{
                if(lc_parser.parse_last_change(0,val as string,"CurrentTrackDuration",typeof(string),out current_track_duration) && current_track_duration != null) {
                    print ("CurrentTrackDuration: %s\n",current_track_duration);
                    position_info.set_range(0,duration_stamp_to_seconds(current_track_duration));
                    duration_label.label=current_track_duration;
                }
            } catch (Error err) {
                warning ("error parsing didl results: %s", err.message);
            }
        }

        private void on_transport_state_changed(GUPnP.LastChangeParser lc_parser, Value val){
            string transport_state=null;
            try{
                if(lc_parser.parse_last_change(0,val as string,"TransportState",typeof(string),out transport_state) && transport_state != null){

                    current_transport_state=transport_state;

                    switch (transport_state){
                        case TRANSPORT_STATE_STOPPED:
                        case TRANSPORT_STATE_PAUSED_PLAYBACK:
                            play_pause_button.image=icon_play;
                            break;
                        case TRANSPORT_STATE_PLAYING:
                            play_pause_button.image=icon_pause;
                            break;
                    }
                    print ("TransportState: %s\n",transport_state);

                }
            } catch (Error err) {
                warning ("error parsing didl results: %s", err.message);
            }

        }

        private bool contains_action(string[] actions, string action){
            foreach (unowned string trans_action in actions){
                if (trans_action == action)
                    return true;
            }
            return false;
        }

        private void on_transport_actions_changed(GUPnP.LastChangeParser lc_parser, Value val){
            // Play, Stop, Pause, Seek, Next, Previous
            string current_transport_actions=null;
            try{
                if(lc_parser.parse_last_change(0,val as string,"CurrentTransportActions",typeof(string),out current_transport_actions) && current_transport_actions != null) {
                    string[] actions=current_transport_actions.split(",");
                    play_pause_button.sensitive = contains_action(actions,TRANSPORT_ACTION_PLAY);
                    play_pause_button.sensitive = contains_action(actions,TRANSPORT_ACTION_PAUSE);
                    previous_button.sensitive = contains_action(actions,TRANSPORT_ACTION_PREVIOUS);
                    next_button.sensitive = contains_action(actions,TRANSPORT_ACTION_NEXT);
                    stop_button.sensitive = contains_action(actions,TRANSPORT_ACTION_STOP);

                    position_info.sensitive= contains_action(actions, TRANSPORT_ACTION_SEEK);
                    print ("CurrentTransportActions: %s\n",current_transport_actions);
                }
            } catch (Error err) {
                warning ("error parsing didl results: %s", err.message);
            }

        }

        public void on_item_available(GUPnP.DIDLLiteParser parser, GUPnP.DIDLLiteItem item){
            title.label="<b>%s</b>\n<i>%s</i>".printf(item.title, item.description!=null?item.description:"");
        }

        private void on_track_metadata_changed(GUPnP.LastChangeParser lc_parser, Value val){
            string current_track_metadata=null;
            try{
                if(lc_parser.parse_last_change(0,val as string,"CurrentTrackMetaData",typeof(string),out current_track_metadata) && current_track_metadata != null){

                    GUPnP.DIDLLiteParser parser = new GUPnP.DIDLLiteParser ();
                    parser.item_available.connect (on_item_available);
                    try {
                        parser.parse_didl (current_track_metadata);
                    } catch (Error err) {
                        warning ("error parsing track_metadata: %s", err.message);
                        title.label="<b></b>\n<i></i>";
                    }

                    print ("CurrentTrackMetaData: %s\n",current_track_metadata);
                }
            } catch (Error err) {
                warning ("error parsing didl results: %s", err.message);
            }

        }

        private void stop_update_timer(){
            if (update_timer!=null && !update_timer.is_destroyed()){
                update_timer.destroy();
            }
        }

        private void start_update_timer(){
            update_timer=new GLib.TimeoutSource(2000);
            update_timer.set_callback(request_renderer_update);
            update_timer.attach(null);
        }

        private void subscribe_to_mediarenderer(UPNPDevice? device){
            stop_update_timer();
            if(active_device != null){
                if (active_device.RenderingControl != null){
                    active_device.RenderingControl.subscribed=false;
                    active_device.RenderingControl.remove_notify("LastChange",on_mediarenderer_notify);
                }
                if (active_device.AVTransport != null){
                    active_device.AVTransport.subscribed=false;
                    active_device.AVTransport.remove_notify("LastChange",on_mediarenderer_notify);
                }
            }
            active_device=device;

            // Local renderer selected
            if (active_device==null)
                return;

            if (active_device.RenderingControl != null){
                active_device.RenderingControl.subscribed=true;
                active_device.RenderingControl.add_notify("LastChange", typeof(string), on_mediarenderer_notify);
            }
            if (active_device.AVTransport != null){
                active_device.AVTransport.subscribed=true;
                active_device.AVTransport.add_notify("LastChange",typeof(string), on_mediarenderer_notify);
            }
            start_update_timer();
        }


        private bool request_renderer_update(){
            active_device.AVTransport.begin_action("GetPositionInfo",position_update,
                    "InstanceID",typeof(int),0);
            return true;
        }

        private int duration_stamp_to_seconds(string duration){
            string[] duration_tokens=duration.split(":",3);
            int seconds=0;
            int multiplicator=3600;
            for(int i=0;i<int.min(3,duration_tokens.length);i++){
                seconds+=int.parse(duration_tokens[i])*multiplicator;
                multiplicator/=60;
            }
            return seconds;
        }

        private void position_update(GUPnP.ServiceProxy proxy, GUPnP.ServiceProxyAction action){
            string track_duration=null;
            string abs_time=null;
            try{
            if (proxy.end_action(action,
                      "TrackDuration", typeof(string), out track_duration,
                      "AbsTime", typeof(string),out abs_time )){
                position_info.set_range(0,duration_stamp_to_seconds(track_duration));
                position_info.set_value(duration_stamp_to_seconds(abs_time));
                duration_label.label=track_duration;
                abs_time_label.label=abs_time;
            }
            }catch(Error e){
                warning("Error receiving position update information!\n%s",e.message); 
            }
        }
    }
}
