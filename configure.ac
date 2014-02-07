dnl Process this file with autoconf to produce a configure script.

AC_INIT(UPNPMediaBrowser, 0.1)

AC_CONFIG_MACRO_DIR([m4])
AC_CONFIG_AUX_DIR([build-aux])


AM_INIT_AUTOMAKE([1.11 no-dist-gzip dist-xz foreign])
AM_SILENT_RULES([yes])
AM_MAINTAINER_MODE
GNOME_MAINTAINER_MODE_DEFINES

AM_PROG_VALAC([0.22.0])
AM_PROG_CC_C_O

GLIB_GSETTINGS
AC_PATH_PROG(GLIB_COMPILE_RESOURCES, glib-compile-resources)

dnl ###########################################################################
dnl Dependencies
dnl ###########################################################################

dnl Run-time dependencies:
dnl * gnome-icon-theme
dnl * xdg-utils (for xdg-email)

PKG_CHECK_MODULES(UPNPMEDIABROWSER, [
    glib-2.0 >= 2.32
    gtk+-3.0
    gupnp-1.0
    gupnp-av-1.0
    gssdp-1.0
    gee-0.8
    libsoup-2.4
])

dnl ###########################################################################
dnl On systems having Gtk 3.10 and higher we use the new headebar
dnl ###########################################################################
PKG_CHECK_MODULES(HEADERBAR, [
    gtk+-3.0 >= 3.10
], use_headerbar=yes, use_headerbar=no)
AM_CONDITIONAL(USE_HEADERBAR, test $use_headerbar = yes)

dnl ###########################################################################
dnl Documentation
dnl ###########################################################################

YELP_HELP_INIT

dnl ###########################################################################
dnl Internationalization
dnl ###########################################################################

IT_PROG_INTLTOOL([0.35.0])
AC_SUBST(GETTEXT_PACKAGE, UPNPMediaBrowser)

dnl ###########################################################################
dnl Files to generate
dnl ###########################################################################

AC_OUTPUT([
Makefile
data/Makefile
po/Makefile.in
src/Makefile
])
