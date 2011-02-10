AM_CPPFLAGS= $(GLIB_CFLAGS) $(GTHREAD_CFLAGS) \
	     $(SOUP_CFLAGS) $(SOUP_GNOME_CFLAGS) \
	     $(XML_CFLAGS) $(REST_CFLAGS) \
             -DLOGFILE=\"/var/log/condor/deltacloud_condor_plugin.log\"

classadplugindir=$(pkgdatadir)/classad_plugin

classadplugin_LTLIBRARIES = deltacloud_classad_plugin.la

deltacloud_classad_plugin_la_SOURCES = deltacloud_classad_plugin.cpp
deltacloud_classad_plugin_la_LIBADD = $(GLIB_LIBS) $(GTHREAD_LIBS) \
				      $(SOUP_LIBS) $(SOUP_GNOME_LIBS) $(XML_LIBS) $(REST_LIBS)\
				      -lclassad
deltacloud_classad_plugin_la_LDFLAGS = -module -avoid-version -shared
