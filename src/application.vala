/*
Copyright 2010 Thomas Schaz (schazet at gmail dot com)

This file is part of UPNPMediaBrowser.

UPNPMediaBrowser is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

UPNPMediaBrowser is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with UPNPMediaBrowser.  If not, see <http://www.gnu.org/licenses/>.
*/

using Config;
using GLib;
using GUPnP;
using Gtk;
namespace UPNPMediaBrowser{

    public class Application : Gtk.Application {
        //public MediaServers mediaservers;
        private static UPNPMediaBrowser.Application _instance;

        public Application(){
            Object (application_id: "schaze.upnpmediabrowser",
                                    flags: ApplicationFlags.HANDLES_OPEN);
        }

        public static new UPNPMediaBrowser.Application get_default ()
        {
            if (_instance == null)
                _instance = new Application ();
            return _instance;
        }

        public void on_UPNPMediaBrowserMain_destroy () {
          /* When window close signal received */
          Gtk.main_quit ();
        }

        public override void activate(){
            UPNPMediaBrowser.UI.Window window = new UPNPMediaBrowser.UI.Window(this);
            window.window_position = WindowPosition.CENTER;
            window.set_default_size (800, 600);
            window.destroy.connect (()=>{on_UPNPMediaBrowserMain_destroy();});
            window.show(); 
            Gtk.main ();
        }

     /* public int run (string[] args) {

          var builder = new Builder ();
          // Getting the glade file 
          builder.add_from_file ("main.glade");
          builder.connect_signals (this);
        Context ctxt;

        try {
            ctxt = new Context (null, null, 0);
        } catch (Error err) {
            critical (err.message);
            return 1;
        }
          mediaservers=new MediaServers(builder,ref ctxt);

          var window = builder.get_object ("UPNPMediaBrowserMain") as Window;
          window.show_all ();

          Gtk.main ();
          return 0;
     }*/

      private static int main (string[] args) {
          print("Thread id: %i\n",(int)Linux.gettid() );
          Intl.bindtextdomain (GETTEXT_PACKAGE, "./locale");
          Intl.bind_textdomain_codeset (GETTEXT_PACKAGE, "UTF-8");
          Intl.textdomain (GETTEXT_PACKAGE);
          GLib.Environment.set_application_name (_("UPNPMediaBrowser"));
          var app=get_default();
          return app.run(args);
        }


    }
}
