AM_CPPFLAGS=-I`ruby -e "require 'rbconfig' ; puts Config::CONFIG['archdir']"` \
            -DDELTACLOUD_INSTALL_DIR=\"$(DELTACLOUD_INSTALL_DIR)\" -DLOGFILE=\"/var/log/condor/deltacloud_condor_plugin.log\"

classadplugindir=$(pkgdatadir)/classad_plugin

classadplugin_LTLIBRARIES = deltacloud_classad_plugin.la

deltacloud_classad_plugin_la_SOURCES = deltacloud_classad_plugin.cpp
deltacloud_classad_plugin_la_LIBADD = -lclassad -lruby
deltacloud_classad_plugin_la_LDFLAGS = -module -avoid-version -shared

classadplugin_DATA = classad_plugin.rb
