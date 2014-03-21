#
# Copyright 2010 Thomas Schaz (schazet at gmail dot com)
#
# This file is part of UPNPMediaBrowser.
#
# UPNPMediaBrowser is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# UPNPMediaBrowser is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with UPNPMediaBrowser.  If not, see <http://www.gnu.org/licenses/>.
#

bin_PROGRAMS = UPNPMediaBrowser

VALASOURCES = application.vala  \
			  upnp_device.vala \
			  browse_treeview.vala \
			  common.vala	\
			  mediarenderer_toolbar.vala  \
			  devices_treeview.vala  \
			  settings_dialog.vala \
			  window.vala

UPNPMediaBrowser_SOURCES = \
	config.vapi \
	$(VALASOURCES) \
	upnpmediabrowser.gresource.c

UPNPMediaBrowser_VALAFLAGS = \
	--pkg gtk+-3.0 \
	--pkg gupnp-1.0 \
	--pkg gupnp-av-1.0 \
	--pkg gssdp-1.0 \
	--pkg glib-2.0 \
	--pkg gee-0.8 \
	--pkg linux \
	--pkg libsoup-2.4 \
	--debug \
	--target-glib 2.38  \
	--gresources "$(top_srcdir)/data/upnpmediabrowser.gresource.xml"

if USE_HEADERBAR
UPNPMediaBrowser_VALAFLAGS += -D USE_HEADERBAR
endif

UPNPMediaBrowser_CFLAGS = \
	-w \
	$(UPNPMEDIABROWSER_CFLAGS) \
	$(WARN_CFLAGS) \
	-DVERSION=\"$(VERSION)\" \
	-DGETTEXT_PACKAGE=\"$(GETTEXT_PACKAGE)\" \
	-DLOCALE_DIR=\"$(localedir)\" \
	-DUI_DIR=\"$(datadir)/ui/\" \
	-DGCONF_DIR=\"/apps/upnpmediabrowser\" \
	-DUPNPMEDIABROWSER_BINARY=\"upnpmediabrowser\"

UPNPMediaBrowser_LDADD = \
	$(UPNPMEDIABROWSER_LIBS)

upnpmediabrowser.gresource.c: $(top_srcdir)/data/upnpmediabrowser.gresource.xml 
		$(AM_V_GEN) $(GLIB_COMPILE_RESOURCES)  --generate-source --sourcedir $(top_srcdir)/data/ --target "$@" "$<"

gsettings_SCHEMAS = $(top_srcdir)/data/upnpmediabrowser.gschema.xml
@GSETTINGS_RULES@

gschemas.compiled: $(top_srcdir)/data/upnpmediabrowser.gschema.xml
	$(GLIB_COMPILE_SCHEMAS) $(top_srcdir)/data/

CLEANFILES = \
	$(patsubst %.vala,%.c,$(filter %.vala, $(SOURCES))) \
	upnpmediabrowser.gresource.c \
	*_vala.stamp

DISTCLEANFILES = \
	Makefile.in
