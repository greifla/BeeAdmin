Summary: Data::HexDump AppCom perl Modules at /apps
Name: apps-perlmod-Data-HexDump-RH55
Version: 0.02
Release: 1
License: GPL
Group: Applications/Web
URL:     http://search.cpan.org/CPAN/authors/id/F/FT/FTASSIN
Source0: http://search.cpan.org/CPAN/authors/id/F/FT/FTASSIN/Data-HexDump-0.02.tar.gz
Distribution: RedHat 5.5 AppCom Linux
Vendor: T-Systems
Packager: Vogler Hartmut <hartmut.vogler@t-systems.com>
BuildRoot: %{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)
BuildRequires:  perl >= 1:5.6.1
Autoreq: 0

%description
Perl Module Data::HexDump installed at /apps/perlmod
This installation can be used in AppCom enviroments 
(or similar cluster enviroments) with rpm --dbpath /apps/rpm

%prep
rm -rf $RPM_BUILD_DIR/Data-HexDump-0.02
zcat $RPM_SOURCE_DIR/Data-HexDump-0.02.tar.gz | tar -xvf -

%build
cd $RPM_BUILD_DIR/Data-HexDump-0.02
%{__perl} Makefile.PL PREFIX=/apps/perlmod
make

%install
rm -rf $RPM_BUILD_ROOT
cd $RPM_BUILD_DIR/Data-HexDump-0.02
pwd
make pure_install PERL_INSTALL_ROOT=$RPM_BUILD_ROOT
find $RPM_BUILD_ROOT -type f -name .packlist -exec rm -f {} ';'
find $RPM_BUILD_ROOT -type f -name '*.bs' -a -size 0 -exec rm -f {} ';'
find $RPM_BUILD_ROOT -type d -depth -exec rmdir {} 2>/dev/null ';'
chmod -R u+w $RPM_BUILD_ROOT/*


%check || :
cd $RPM_BUILD_DIR/Data-HexDump-0.02
#make test

%clean
rm -rf $RPM_BUILD_ROOT

%files
%defattr(-,root,root,-)
/apps/perlmod/bin/*
/apps/perlmod/lib/perl5/site_perl/5.8.8/Data/*.pm
/apps/perlmod/share/man/man*/*

