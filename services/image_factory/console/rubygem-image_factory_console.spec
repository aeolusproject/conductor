# Generated from image_factory_console-0.2.0.gem by gem2rpm -*- rpm-spec -*-
%define ruby_sitelib %(ruby -rrbconfig -e "puts Config::CONFIG['sitelibdir']")
%define gemdir %(ruby -rubygems -e 'puts Gem::dir' 2>/dev/null)
%define gemname image_factory_console
%define geminstdir %{gemdir}/gems/%{gemname}-%{version}

Summary: QMF Console for Aeolus Image Factory
Name: rubygem-%{gemname}
Version: 0.2.0
Release: 1%{?dist}%{?extra_release}
Group: Development/Languages
License: GPLv2+ or Ruby
URL: http://aeolusproject.org
Source0: %{gemname}-%{version}.gem
BuildRoot: %{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)
Requires: rubygems
# These can't be deduced by gem2rpm
Requires: qpid-cpp-client >= 0.8-6
Requires: ruby-qpid-qmf >= 0.8-6
Requires: qpid-qmf >= 0.8-6

BuildRequires: rubygems
BuildArch: noarch
Provides: rubygem(%{gemname}) = %{version}

%description
QMF Console for Aeolus Image Factory


%prep

%build

%install
rm -rf %{buildroot}
mkdir -p %{buildroot}%{gemdir}
gem install --local --install-dir %{buildroot}%{gemdir} \
            --force --rdoc %{SOURCE0}

%clean
rm -rf %{buildroot}

%files
%defattr(-, root, root, -)
%{gemdir}/gems/%{gemname}-%{version}/
%doc %{gemdir}/doc/%{gemname}-%{version}
%{gemdir}/cache/%{gemname}-%{version}.gem
%{gemdir}/specifications/%{gemname}-%{version}.gemspec


%changelog
* Thu Mar 10 2011  <morazi@redhat.com> - 0.2.0-1
- Initial package
