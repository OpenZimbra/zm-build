#
# spec file for zimbra.rpm
#
Summary: Zimbra Mail
Name: zimbra-logger
Version: @@VERSION@@
Release: 1%{?dist}
License: ZPL and other
Group: Applications/Messaging
URL: http://www.zimbra.com
Vendor: Zimbra, Inc.
Packager: Zimbra, Inc.
BuildRoot: /opt/zimbra
AutoReqProv: no
requires: zimbra-core

%description
Best email money can buy

%define __spec_install_pre /bin/true

%define __spec_install_post /usr/lib/rpm/brp-compress /usr/lib/rpm/brp-strip-comment-note %{nil}

%prep

%build

%install

%pre

%post

%preun

%postun

%files
