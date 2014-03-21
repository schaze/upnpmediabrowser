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

using Gtk;
using Gdk;
using UPNPMediaBrowser;
using GUPnP;

namespace UPNPMediaBrowser.Common{
    public Gdk.Pixbuf get_icon(string name, int size=24){
        Gtk.IconTheme theme=Gtk.IconTheme.get_default();
        try {
            return theme.load_icon(name,size,0);
        }catch(Error e){
            print ("Error fetching icon [%s]: %s\n",name, e.message);
            return (Gdk.Pixbuf)null;
        }
    }

    public async uint8[] download_url(string url){
        File file=File.new_for_uri(url);
        try {
            uint8[] contents;
            string etag_out;
            yield file.load_contents_async(null,out contents, out etag_out);
            return contents;
        }catch (Error e) { 
             print ("Error: %s\n", e.message);
             return (uint8[])null;
        }
    }

    public async Gdk.Pixbuf download_image(string url,int width,int height){
        uint8[] contents=yield download_url(url);
        float aheight=(float)height;
        float awidth=(float)width;
        if (contents==null)
            return (Gdk.Pixbuf)null;
        Gdk.PixbufLoader loader=new Gdk.PixbufLoader();
        try{
            loader.write(contents);
            Gdk.Pixbuf image=loader.get_pixbuf();
            loader.close();
            // Do some basic apect ration scaling when one of the dimensions was passed as 0
            if (height==0)
                aheight=(float)image.height*(awidth/(float)image.width);
            if (width==0)
                awidth=(float)image.width*(aheight/(float)image.height);
            return image.scale_simple((int)awidth,(int)aheight,InterpType.BILINEAR);
        }catch(Error e){
            print("Error downloading image: %s\n",e.message);
            return (Gdk.Pixbuf)null;
        }
    }

}
