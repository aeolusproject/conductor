# Generated from image_factory_connector-0.0.1.gem by gem2rpm -*- rpm-spec -*-
%define ruby_sitelib %(ruby -rrbconfig -e "puts Config::CONFIG['sitelibdir']")
%define gemdir %(ruby -rubygems -e 'puts Gem::dir' 2>/dev/null)
%define gemname image_factory_connector
%define geminstdir %{gemdir}/gems/%{gemname}-%{version}

Summary: Sinatra microapp to talk to  Aeolus Image Factory QMF console
Name: rubygem-%{gemname}
Version: 0.0.3
Release: 1%{?dist}%{?extra_release}
Group: Development/Languages
License: GPLv2+ or Ruby
URL: http://aeolusproject.org
Source0: %{gemname}-%{version}.gem
Source1: aeolus-connector.init
BuildRoot: %{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)
Requires: rubygems
Requires: rubygem(image_factory_console) >= 0.2.0
Requires: rubygem(builder) >= 2.1.2
Requires: rubygem(sinatra) >= 1.0
Requires: rubygem(rspec) >= 1.3.0
Requires: rubygem(typhoeus) >= 0.1.31
BuildRequires: rubygems
BuildArch: noarch
Provides: rubygem(%{gemname}) = %{version}

%description
REST api and callback mechanism to wrap qmf for the Aeolus project


%prep

%build

%install
rm -rf %{buildroot}
mkdir -p %{buildroot}%{gemdir}
gem install --local --install-dir %{buildroot}%{gemdir} \
            --force --rdoc %{SOURCE0}
mkdir -p %{buildroot}/%{_bindir}
mv %{buildroot}%{gemdir}/bin/* %{buildroot}/%{_bindir}
rmdir %{buildroot}%{gemdir}/bin
find %{buildroot}%{geminstdir}/bin -type f | xargs chmod a+x
mkdir -p %{buildroot}/etc/init.d
cp %{SOURCE1}  %{buildroot}/etc/init.d/aeolus-connector
%{__mkdir} -p %{buildroot}%{_sysconfdir}
%{__cp}  %{buildroot}%{geminstdir}/lib/conf/aeolus_connector.yml %{buildroot}%{_sysconfdir}


%clean
rm -rf %{buildroot}

%files
%defattr(-, root, root, -)
%{_bindir}/image_factory_connector
%{_sysconfdir}/aeolus_connector.yml
%{gemdir}/gems/%{gemname}-%{version}/
%doc %{gemdir}/doc/%{gemname}-%{version}
%{gemdir}/cache/%{gemname}-%{version}.gem
%{gemdir}/specifications/%{gemname}-%{version}.gemspec
%attr(755,root,root) /etc/init.d/aeolus-connector

%post
# Register the service
/sbin/chkconfig --add aeolus-connector

%preun
if [ $1 = 0 ]; then
	/sbin/service aeolus-connector stop > /dev/null 2>&1
	/sbin/chkconfig --del aeolus-connector
fi

%changelog
* Tue May 10 2011 Jason Guiditta <jguiditt@redhat.com> - 0.0.3-1
 - Drop the new yml file for connector into /etc so it can be altered by
   the user (or puppet).
 - Update the initscript to point to rpm config file
 - Bump version for rpm/gem


* Thu Apr 14 2011 Jason Guiditta <jguiditt@redhat.com> - 0.0.2-1
- Clean up the connector startup script so it starts only one process
- Stops/restarts more reliably
- Fix the rackup file for proper daemonization


* Mon Mar 14 2011 Angus Thomas <athomas@redhat.com> - 0.0.1-1
- Initial package
