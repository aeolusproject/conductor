# vim: sw=4:ts=4:et
#
# Copyright 2011 Red Hat, Inc.
#
# This software is licensed to you under the GNU General Public
# License as published by the Free Software Foundation; either version
# 2 of the License (GPLv2) or (at your option) any later version.
# There is NO WARRANTY for this software, express or implied,
# including the implied warranties of MERCHANTABILITY,
# NON-INFRINGEMENT, or FITNESS FOR A PARTICULAR PURPOSE. You should
# have received a copy of GPLv2 along with this software; if not, see
# http://www.gnu.org/licenses/old-licenses/gpl-2.0.txt.


%global homedir %{_datarootdir}/%{name}

Name:          converge-ui
Summary:       A collection of assets
Group:         Applications/System
License:       GPLv2
URL:           http://www.katello.org
Version:       0.2
Release:       1%{?dist}
Source0:       %{name}-%{version}.tar.gz
BuildRoot:     %{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)

BuildArch:     noarch

%description
A common set of web assets.

%prep
%setup -q 

%build

%install
rm -rf $RPM_BUILD_ROOT
install -m0755 -d %{buildroot}%{homedir}
install -m0755 -d %{buildroot}%{homedir}/javascripts/
install -m0755 -d %{buildroot}%{homedir}/rails/
install -m0755 -d %{buildroot}%{homedir}/stylesheets/

cp -R javascripts/* %{buildroot}%{homedir}/javascripts/
cp -R rails/* %{buildroot}%{homedir}/rails
cp -R stylesheets/* %{buildroot}%{homedir}/stylesheets/

%clean
rm -rf $RPM_BUILD_ROOT

%files 
%defattr(755, root, root)
%{homedir}
%doc README LICENSE

%changelog
* Thu Mar 29 2012 Eric D Helms <ehelms@redhat.com> 0.2-1
- new package built with tito

* Wed Mar 28 2012 Eric D Helms <ehelms@redhat.com> 0.1-1
- Changes to spec file. (ehelms@redhat.com)
