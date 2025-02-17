# SPDX-License-Identifier: GPL-2.0-only

Copy()
{
   if [ $# -ne 2 ]
   then
      echo "Usage: Copy <file1> <file2>" 1>&2
      exit 1;
   fi

   local src_file="$1"; shift;
   local dest_file="$1"; shift;

   mkdir -p "$(dirname "$dest_file")"

   cp -f "$src_file" "$dest_file"
}

Cpy2()
{
   if [ $# -ne 2 ]
   then
      echo "Usage: Cpy2 <file1> <dir>" 1>&2
      exit 1;
   fi

   local src_file="$1"; shift;
   local dest_dir="$1"; shift;

   mkdir -p "$dest_dir"

   cp -f "$src_file" "$dest_dir"
}

Log()
{
    echo "${currentPackage}: $*" >&2
}

CreatePackage()
{
    if [ $# -ne 1 ]
    then
      echo "Usage: CreatePackage <os-name>" 1>&2
      exit 1
    fi

    if [[ $1 == UBUNTU* ]]
    then
        CreateDebianPackage
    elif [[ $1 == RHEL* ]]
    then
        CreateRhelPackage
    else
        echo "OS not supported. Run using UBUNTU or RHEL system. "
        exit 1
    fi

    if [ $? -ne 0 ]; then
        Log "### package building failed ###"
        exit 1
    else
        Log "package successfully created"
    fi
}

PkgImageDirs()
{
    for d in "$@" ; do
        mkdir -p ${repoDir}/zm-build/${currentPackage}/$d
    done
}

PkgImageBinCmds()
{
    local srcdir="$1"
    local target="${repoDir}/zm-build/${currentPackage}/opt/zimbra/bin"
    mkdir -p $target
    shift
    while [ "$1" ]; do
        cp $srcdir/$1 $target
        chmod ugo+x $target/$1
        shift
    done
}

DebianFinish()
{
    packageDir=`realpath $packageDir`
    mkdir -p ${packageDir} ${repoDir}/zm-build/${currentPackage}/DEBIAN

    # fixme: check for post script
    cat ${repoDir}/zm-build/rpmconf/Spec/${currentScript}.deb \
    | sed -e "s/@@VERSION@@/${releaseNo}.${releaseCandidate}.${buildNo}.${os/_/.}/" \
          -e "s/@@ARCH@@/${arch}/" \
          -e "s/@@MORE_DEPENDS@@/${MORE_DEPENDS}/" \
          -e "/^%post$/ r ${currentPackage}.post" \
    > ${repoDir}/zm-build/${currentPackage}/DEBIAN/control

    (cd ${repoDir}/zm-build/${currentPackage}; dpkg -b ${repoDir}/zm-build/${currentPackage} ${packageDir})
}

DebianBegin()
{
    PkgImageDirs /DEBIAN
    if [ -f ${repoDir}/zm-build/rpmconf/Spec/Scripts/${currentScript}.post ]; then
        cat ${repoDir}/zm-build/rpmconf/Spec/Scripts/${currentScript}.post >> ${repoDir}/zm-build/${currentPackage}/DEBIAN/postinst
        chmod ugo+x ${repoDir}/zm-build/${currentPackage}/DEBIAN/postinst
    fi

    if [ -f ${repoDir}/zm-build/rpmconf/Spec/Scripts/${currentScript}.pre ]; then
        cat ${repoDir}/zm-build/rpmconf/Spec/Scripts/${currentScript}.pre >> ${repoDir}/zm-build/${currentPackage}/DEBIAN/preinst
        chmod ugo+x ${repoDir}/zm-build/${currentPackage}/DEBIAN/preinst
    fi
}

currentScript=`basename $0 | cut -d "." -f 1`
currentPackage=`echo ${currentScript}build | cut -d "-" -f 2`
