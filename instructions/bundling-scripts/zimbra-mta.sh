#!/bin/bash
#
# ***** BEGIN LICENSE BLOCK *****
# Zimbra Collaboration Suite Server
# Copyright (C) 2009, 2010, 2011, 2013, 2014, 2015, 2016 Synacor, Inc.
#
# This program is free software: you can redistribute it and/or modify it under
# the terms of the GNU General Public License as published by the Free Software Foundation,
# version 2 of the License.
#
# This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
# without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
# See the GNU General Public License for more details.
# You should have received a copy of the GNU General Public License along with this program.
# If not, see <https://www.gnu.org/licenses/>.
# ***** END LICENSE BLOCK *****

# Shell script to create zimbra mta package


#-------------------- Configuration ---------------------------

    currentScript=`basename $0 | cut -d "." -f 1`                          # zimbra-mta
    currentPackage=`echo ${currentScript}build | cut -d "-" -f 2` # mtabuild


#-------------------- Build Package ---------------------------
main()
{
    log 1 "Create package directories"
    install_dirs \
        opt/zimbra/data/altermime \
        opt/zimbra/data/cbpolicyd/db \
        opt/zimbra/data/clamav \
        opt/zimbra/data/opendkim \
        opt/zimbra/data/postfix

    log 1 "Copy package files"
    install_file zm-build/rpmconf/Env/sudoers.d/02_${currentScript} etc/sudoers.d/
    install_file zm-postfix/conf/postfix/master.cf.in               opt/zimbra/common/conf/
    install_file zm-postfix/conf/postfix/tag_as_foreign.re.in       opt/zimbra/common/conf/
    install_file zm-postfix/conf/postfix/tag_as_originating.re.in   opt/zimbra/common/conf/
    install_file zm-amavis/conf/amavisd/mysql/antispamdb.sql        opt/zimbra/data/amavisd/mysql/

    CreatePackage "${os}"
}

#-------------------- Util Functions ---------------------------

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

source "$SCRIPT_DIR/utils.sh"

CreateDebianPackage()
{
    mkdeb_gen_control
}

CreateRhelPackage()
{
    cat ${repoDir}/zm-build/rpmconf/Spec/${currentScript}.spec | \
        sed -e "s/@@VERSION@@/${releaseNo}_${releaseCandidate}_${buildNo}.${os}/" \
            -e "s/@@RELEASE@@/${buildTimeStamp}/" \
            -e "s/@@MTA_PROVIDES@@/smtpdaemon/" \
            -e "s/^Copyright:/Copyright:/" \
            -e "/^%post$/ r ${repoDir}/zm-build/rpmconf/Spec/Scripts/${currentScript}.post" > ${repoDir}/zm-build/${currentScript}.spec
    (cd ${repoDir}/zm-build/mtabuild; find opt -maxdepth 2 -type f -o -type l \
        | sed -e 's|^|%attr(-, zimbra, zimbra) /|' >> \
        ${repoDir}/zm-build/${currentScript}.spec )
    echo "%attr(440, root, root) /etc/sudoers.d/02_zimbra-mta" >> \
        ${repoDir}/zm-build/${currentScript}.spec
    echo "%attr(-, zimbra, zimbra) /opt/zimbra/common/conf/master.cf.in" >> \
        ${repoDir}/zm-build/${currentScript}.spec
    echo "%attr(-, zimbra, zimbra) /opt/zimbra/common/conf/tag_as_foreign.re.in" >> \
        ${repoDir}/zm-build/${currentScript}.spec
    echo "%attr(-, zimbra, zimbra) /opt/zimbra/common/conf/tag_as_originating.re.in" >> \
        ${repoDir}/zm-build/${currentScript}.spec
    echo "%attr(-, zimbra, zimbra) /opt/zimbra/data/amavisd" >> \
        ${repoDir}/zm-build/${currentScript}.spec
    echo "%attr(-, zimbra, zimbra) /opt/zimbra/data/clamav" >> \
        ${repoDir}/zm-build/${currentScript}.spec
    echo "%attr(-, zimbra, zimbra) /opt/zimbra/data/cbpolicyd" >> \
        ${repoDir}/zm-build/${currentScript}.spec
    echo "%attr(-, zimbra, zimbra) /opt/zimbra/data/opendkim" >> \
        ${repoDir}/zm-build/${currentScript}.spec
    (cd ${repoDir}/zm-build/${currentPackage}; \
        rpmbuild --target ${arch} --define '_rpmdir ../' --buildroot=${repoDir}/zm-build/${currentPackage} -bb ${repoDir}/zm-build/${currentScript}.spec )
}

############################################################################
main "$@"
