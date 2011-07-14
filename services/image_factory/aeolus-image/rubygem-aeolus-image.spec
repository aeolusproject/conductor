%define ruby_sitelib %(ruby -rrbconfig -e "puts Config::CONFIG['sitelibdir']")
%define gemdir %(ruby -rubygems -e 'puts Gem::dir' 2>/dev/null)
%define gemname aeolus-image
%define geminstdir %{gemdir}/gems/%{gemname}-%{version}
%define mandir /usr/man/man1

Summary: Commandline interface for working with the Aeolus cloud suite
Name: rubygem-%{gemname}
Version: 0.0.1
Release: 1%{?dist}%{?extra_release}
Group: Development/Languages
License: GPLv2+ or Ruby
URL: http://aeolusproject.org

Source0: %{gemname}-%{version}.gem
BuildRoot: %{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)
Requires: rubygems
Requires: rubygem(nokogiri) >= 1.4.0
Requires: rubygem(rest-client)
Requires: rubygem(image_factory_console) >= 0.4.0

BuildRequires: rubygems
BuildArch: noarch
Provides: rubygem(%{gemname}) = %{version}

Obsoletes: rubygem-aeolus-cli
Provides: rubygem(aeolus-cli)

%description
QMF Console for Aeolus Image Factory

%prep

%build

%install
rm -rf %{buildroot}

mkdir -p %{buildroot}%{gemdir}
gem install --local --install-dir %{buildroot}%{gemdir} \
            --force --rdoc %{SOURCE0}

mkdir -p %{buildroot}/%{_bindir}
mv %{buildroot}%{gemdir}/bin/* %{buildroot}/%{_bindir}
find %{buildroot}%{geminstdir}/bin -type f | xargs chmod a+x
rmdir %{buildroot}%{gemdir}/bin

mkdir -p %{buildroot}%{mandir}
mv %{buildroot}%{geminstdir}/man/* %{buildroot}%{mandir}

%clean
rm -rf %{buildroot}

%files
%defattr(-, root, root, -)
%{_bindir}/aeolus-image
%{gemdir}/gems/%{gemname}-%{version}/
%doc %{gemdir}/doc/%{gemname}-%{version}
%{gemdir}/cache/%{gemname}-%{version}.gem
%{gemdir}/specifications/%{gemname}-%{version}.gemspec
%{mandir}

%changelog
* Mon Jul 04 2011  <mtaylor@redhat.com>  - 0.0.1-1
- Added man files
* Wed Jun 15 2011  <jguiditt@redhat.com> - 0.0.1-1
- Initial package
