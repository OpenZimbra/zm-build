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

# Shell script to create zimbra dnscache package


#-------------------- Configuration ---------------------------

    currentScript=`basename $0 | cut -d "." -f 1`                          # zimbra-dnscache
    currentPackage=`echo ${currentScript}build | cut -d "-" -f 2` # dnscachebuild


#-------------------- Build Package ---------------------------
main()
{
    log 1 "Create package directories"
    mkdir -p ${repoDir}/zm-build/${currentPackage}/etc/sudoers.d
    mkdir -p ${repoDir}/zm-build/${currentPackage}/opt/zimbra/data/dns/ca
    mkdir -p ${repoDir}/zm-build/${currentPackage}/opt/zimbra/data/dns/trust

    CreatePackage "${os}"
}

#-------------------- Util Functions ---------------------------

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

source "$SCRIPT_DIR/utils.sh"

CreateDebianPackage()
{
    mkdir -p ${repoDir}/zm-build/${currentPackage}/etc/resolvconf/update.d
    cp ${repoDir}/zm-dnscache/conf/dns/zimbra-unbound ${repoDir}/zm-build/${currentPackage}/etc/resolvconf/update.d
    cp ${repoDir}/zm-build/rpmconf/Env/sudoers.d/02_${currentScript}.deb ${repoDir}/zm-build/${currentPackage}/etc/sudoers.d/02_${currentScript}

    mkdeb_gen_control
}

CreateRhelPackage()
{
    cp ${repoDir}/zm-build/rpmconf/Env/sudoers.d/02_${currentScript}.rpm ${repoDir}/zm-build/${currentPackage}/etc/sudoers.d/02_${currentScript}

    cat ${repoDir}/zm-build/rpmconf/Spec/${currentScript}.spec | \
        sed -e "s/@@VERSION@@/${releaseNo}_${releaseCandidate}_${buildNo}.${os}/" \
            -e "s/@@RELEASE@@/${buildTimeStamp}/" \
            -e "s/^Copyright:/Copyright:/" \
            -e "/^%post$/ r ${repoDir}/zm-build/rpmconf/Spec/Scripts/${currentScript}.post" > ${repoDir}/zm-build/${currentScript}.spec
    echo "%attr(-, zimbra, zimbra) /opt/zimbra/data/dns" >> \
        ${repoDir}/zm-build/${currentScript}.spec
    echo "%attr(440, root, root) /etc/sudoers.d/02_zimbra-dnscache" >> \
        ${repoDir}/zm-build/${currentScript}.spec
    (cd ${repoDir}/zm-build/${currentPackage}; \
        rpmbuild --target ${arch} --define '_rpmdir ../' --buildroot=${repoDir}/zm-build/${currentPackage} -bb ${repoDir}/zm-build/${currentScript}.spec )
}

############################################################################
main "$@"