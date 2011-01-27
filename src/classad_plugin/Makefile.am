AM_CPPFLAGS= $(GLIB_CFLAGS) $(GTHREAD_CFLAGS) \
	     $(SOUP_CFLAGS) $(SOUP_GNOME_CFLAGS) \
	     $(XML_CFLAGS) $(REST_CFLAGS) \
             -DLOGFILE=\"/var/log/condor/conductor_condor_plugin.log\"

classadplugindir=$(pkgdatadir)/classad_plugin

classadplugin_LTLIBRARIES = conductor_classad_plugin.la

conductor_classad_plugin_la_SOURCES = conductor_classad_plugin.cpp
conductor_classad_plugin_la_LIBADD = $(GLIB_LIBS) $(GTHREAD_LIBS) \
				      $(SOUP_LIBS) $(SOUP_GNOME_LIBS) $(XML_LIBS) $(REST_LIBS)\
				      -lclassad
conductor_classad_plugin_la_LDFLAGS = -module -avoid-version -shared

