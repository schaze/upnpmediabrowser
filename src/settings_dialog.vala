using Config;
using Gtk;
using UPNPMediaBrowser;
using GUPnP;

namespace UPNPMediaBrowser.UI{
    [GtkTemplate (ui = "/schaze/upnpmediabrowser/ui/settings.ui")]
    public class SettingsDialog: Gtk.ApplicationWindow{
        private GLib.Settings settings = new GLib.Settings ("org.schaze.upnpmediabrowser.general");
        [GtkChild]
        private Gtk.CheckButton default_player;
        [GtkChild]
        private Gtk.Label mediaplayer_text_label;
        [GtkChild]
        private Gtk.Image player_icon;
        [GtkChild]
        private Gtk.Label player_name;
        [GtkChild]
        private Gtk.Button choose_player_button;
        [GtkChild]
        private Gtk.CheckButton use_custom_player;
        [GtkChild]
        private Gtk.Entry custom_player_command;

        private string mediaplayer_name;
        private string mediaplayer_commandline;

        public SettingsDialog (UPNPMediaBrowser.Application app){
            Object (application:app);

            mediaplayer_name=settings.get_string("mediaplayer-name");
            mediaplayer_commandline=settings.get_string("mediaplayer-commandline");
            init_widgets();
        }

        private void init_widgets(){
            set_default_size(600,250);
            width_request=600;
            height_request=250;
            set_keep_above(true);


            default_player.active=settings.get_boolean("use-default-mediaplayer");
            use_custom_player.active=settings.get_boolean("use-custom-mediaplayer");
            custom_player_command.text=settings.get_string("custom-mediaplayer-commandline");

            apply_ui_update();
        }

        private void set_player_info(){
            List<AppInfo> players=AppInfo.get_all_for_type("video/mp4");
            foreach(unowned AppInfo info in players){
                if (info.get_display_name()==settings.get_string("mediaplayer-name")){
                    player_icon.gicon=info.get_icon();
                    player_name.label=info.get_display_name();
                    break;
                }
            }
        }

        private void apply_ui_update(){
            if (default_player.active){
                choose_player_button.sensitive=false;
                AppInfo info=AppInfo.get_default_for_type("video/mp4",true);
                player_icon.gicon=info.get_icon();
                player_name.label=info.get_display_name();
            }else{
                choose_player_button.sensitive=true;
                set_player_info();
            }
            if (use_custom_player.active){
                default_player.sensitive=false;
                mediaplayer_text_label.sensitive=false;
                player_icon.sensitive=false;
                player_name.sensitive=false;
                choose_player_button.sensitive=false;
                custom_player_command.visible=true;
            }else{
                default_player.sensitive=true;
                mediaplayer_text_label.sensitive=true;
                player_icon.sensitive=true;
                player_name.sensitive=true;
                custom_player_command.visible=false;
            }
        }

        [GtkCallback]
        private void  default_player_toggled() {
            apply_ui_update();
        }

        [GtkCallback]
        private void  use_custom_player_toggled() {
            apply_ui_update();
        }

        [GtkCallback]
        private void  choose_player() {
            Gtk.AppChooserDialog dialog = new Gtk.AppChooserDialog.for_content_type (this, 0, "video/mp4");
            if (dialog.run () == Gtk.ResponseType.OK) {
                AppInfo info = dialog.get_app_info ();
                if (info != null) {
                    player_icon.gicon=info.get_icon();
                    player_name.label=info.get_display_name();
                    //custom_player.text=player_command;
                    mediaplayer_name=info.get_display_name();
                    mediaplayer_commandline=info.get_commandline();
                }
            }
            dialog.hide();
            dialog.close ();
        }

        [GtkCallback]
        private void  on_save_button_clicked() {
            settings.set_boolean("use-default-mediaplayer",default_player.active);
            settings.set_string("mediaplayer-name",mediaplayer_name);
            settings.set_string("mediaplayer-commandline",mediaplayer_commandline);
            settings.set_boolean("use-custom-mediaplayer",use_custom_player.active);
            settings.set_string("custom-mediaplayer-commandline",custom_player_command.text);
            close();

        }
        [GtkCallback]
        private void  on_cancel_button_clicked() {
            close();
        }
    }
}
