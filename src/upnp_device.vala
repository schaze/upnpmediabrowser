using GUPnP;
using UPNPMediaBrowser.Common;
using Gtk;
using Gdk;

namespace UPNPMediaBrowser{

    public class UPNPDevice : GLib.Object{
        private string name;
        public string Name{
            get { return name; }
        }
        private GUPnP.DeviceProxy device;
        public GUPnP.DeviceProxy Device { 
            get { return device; }
            set { device=value;  }
        }

        private Gdk.Pixbuf device_icon=null;
        private string udn=null;

        private GUPnP.ServiceProxy rendering_control=null;
        public GUPnP.ServiceProxy RenderingControl{
            get{
                return rendering_control;
            }
        }
        public bool has_rendering_control{
            get{
                return rendering_control!=null;
            }
        }

        private GUPnP.ServiceProxy av_transport=null;
        public GUPnP.ServiceProxy AVTransport{
            get{
                return av_transport;
            }
        }
        public bool has_av_transport{
            get{
                return av_transport!=null;
            }
        }

        private GUPnP.ServiceProxy content_directory=null;
        public GUPnP.ServiceProxy ContentDirectory{
            get{
                return content_directory;
            }
        }
        public bool has_content_directory{
            get{
                return content_directory!=null;
            }
        }

        public UPNPDevice(GUPnP.DeviceProxy device){
            this.device=device;
            udn=device.udn;
            name = this.device.get_friendly_name();
            rendering_control=device.get_service("urn:schemas-upnp-org:service:RenderingControl") as ServiceProxy;
            av_transport=device.get_service("urn:schemas-upnp-org:service:AVTransport") as ServiceProxy;
            content_directory=device.get_service("urn:schemas-upnp-org:service:ContentDirectory") as ServiceProxy;
        }

        public async Gdk.Pixbuf load_device_icon(int width, int height){
            if (device_icon!=null)
                return device_icon;

            string mime;
            int depth,owidth,oheight;
            string url=device.get_icon_url(null,-1,-1,-1, true, out mime, out depth, out owidth, out oheight);
            device_icon= yield download_image(url,width,height);
            return device_icon;
        }

        public bool compare_to(GUPnP.DeviceProxy cmp_device){
            print("Comparing me [%s] to [%s]\n",udn, cmp_device.udn);
            if (cmp_device==null)
                return false;
            return udn == cmp_device.udn;
        }
    }
}
