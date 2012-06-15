# Copyright (C) 2011 Red Hat, Inc.
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

VERSION = 0.10.2

# For Release: 0..., set _conductor_dev=1 so that we get extra_release.GIT-
# annotated rpm version strings.
_conductor_dev =  $(shell grep -q '^[[:space:]]*Release:[[:space:]]*0' \
   aeolus-conductor.spec.in && echo 1 || :)

# use $(shell...) here to collect the git head and date *once* per make target.
# that ensures that if multiple actions happen in the same target (like the
# multiple RPM builds in the rpms target), they all use the same date
git_head	= $(shell git log -1 --pretty=format:%h)
date		= $(shell date --utc +%Y%m%d%H%M%S)
GIT_RELEASE	= $(date)git$(git_head)
RPMDIR		= $$(rpm --eval '%{_rpmdir}')
RPM_FLAGS	= --define "conductor_cache_dir $(CONDUCTOR_CACHE_DIR)"

# Only include a githash in the %{release} when _conductor_dev is enabled
ifeq ($(_conductor_dev),)
EXTRA_RELEASE = ""
else
EXTRA_RELEASE = ".$(GIT_RELEASE)"
endif

dist:
	sed -e "s|@VERSION@|$(VERSION)|;s|^\(Release:[^%]*\)|\1$(EXTRA_RELEASE)|" aeolus-conductor.spec.in > aeolus-conductor.spec

	mkdir -p dist/aeolus-conductor-$(VERSION)
	cp -a aeolus-conductor.spec AUTHORS conf COPYING Makefile src \
		dist/aeolus-conductor-$(VERSION)
	rm -f dist/aeolus-conductor-$(VERSION)/src/vendor/converge-ui/converge-ui-devel.spec
	tar -C dist -zcvf aeolus-conductor-$(VERSION).tar.gz aeolus-conductor-$(VERSION)


rpms: dist
	rpmbuild $(RPM_FLAGS) -ta aeolus-conductor-$(VERSION).tar.gz

srpms: dist
	rpmbuild $(RPM_FLAGS) -ts aeolus-conductor-$(VERSION).tar.gz

publish: rpms
	mkdir -p $(CONDUCTOR_CACHE_DIR)
	rsync -aq $(shell rpm --eval '%{_rpmdir}')/ $(CONDUCTOR_CACHE_DIR)/conductor/
	rsync -aq $(shell rpm --eval '%{_srcrpmdir}')/ $(CONDUCTOR_CACHE_DIR)/conductor/src
	createrepo $(CONDUCTOR_CACHE_DIR)/conductor

genlangs:
	cd src && rake updatepo && rake makemo

clean:
	rm -rf dist aeolus-conductor-$(VERSION).tar.gz aeolus-conductor.spec

.PHONY: dist rpms publish srpms genlangs
