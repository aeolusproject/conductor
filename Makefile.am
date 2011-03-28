# Copyright (C) 2008 Red Hat, Inc.
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; version 2 of the License.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
# MA  02110-1301, USA.  A copy of the GNU General Public License is
# also available at http://www.gnu.org/copyleft/gpl.html.

CONDUCTOR_CACHE_DIR	?= $(HOME)/conductor-cache

EXTRA_DIST =			\
  .gitignore			\
  aeolus-conductor.spec		\
  aeolus-conductor.spec.in	\
  conf				\
  src

DISTCLEANFILES = $(PACKAGE)-$(VERSION).tar.gz

# For Release: 0..., set _conductor_dev=1 so that we get extra_release.GIT-
# annotated rpm version strings.
_conductor_dev = \
 $(shell grep -q '^[[:space:]]*Release:[[:space:]]*0' \
   $(srcdir)/*.spec.in && echo 1 || :)

git_head	= $$(git log -1 --pretty=format:%h)
GIT_RELEASE	= $$(date --utc +%Y%m%d%H%M%S)git$(git_head)
RPMDIR		= $$(rpm --eval '%{_rpmdir}')
RPM_FLAGS	= --define "conductor_cache_dir $(CONDUCTOR_CACHE_DIR)"
RPM_FLAGS	+= $(if $(_conductor_dev),--define "extra_release .$(GIT_RELEASE)")
RAKE_EXTRA_RELEASE	= $(if $(_conductor_dev),"extra_release=.$(GIT_RELEASE)")

SUBDIRS = src/classad_plugin

ACLOCAL_AMFLAGS = -I m4

rpms: dist
	cd services/image_factory/console; rake rpms $(RAKE_EXTRA_RELEASE)
	cd services/image_factory/image_factory_connector; rake rpms $(RAKE_EXTRA_RELEASE)
	rpmbuild $(RPM_FLAGS) -ta $(distdir).tar.gz

srpms: dist
	rpmbuild $(RPM_FLAGS) -ts $(distdir).tar.gz

publish: rpms
	mkdir -p $(CONDUCTOR_CACHE_DIR)
	rsync -aq $(shell rpm --eval '%{_rpmdir}')/ $(CONDUCTOR_CACHE_DIR)/conductor/
	rsync -aq $(shell rpm --eval '%{_srcrpmdir}')/ $(CONDUCTOR_CACHE_DIR)/conductor/src
	createrepo $(CONDUCTOR_CACHE_DIR)/conductor

genlangs:
	cd src && rake updatepo && rake makemo

.PHONY: rpms publish srpms genlangs
