#!/bin/bash
# SPDX-License-Identifier: GPL-2.0-only

ID=`id -u`

if [ "x$ID" != "x0" ]; then
  echo "Run as root!"
  exit 1
fi

if [ ! -x "/usr/bin/perl" ]; then
  echo "ERROR: System perl at /usr/bin/perl must be present before installation."
  exit 1
fi

MYDIR="$(cd "$(dirname "$0")" && pwd)"

. ./util/utilfunc.sh

for i in ./util/modules/*sh; do
	. $i
done

UNINSTALL="no"
SOFTWAREONLY="no"
SKIP_UPGRADE_CHECK="no"
ALLOW_PLATFORM_OVERRIDE="no"
FORCE_UPGRADE="no"

usage() {
  echo "$0 [-r <dir> -l <file> -a <file> -u -s -c type -x -h] [defaultsfile]"
  echo ""
  echo "-h|--help               Usage"
  echo "-r|--restore <dir>      Restore contents of <dir> to localconfig"
  echo "-s|--softwareonly       Software only installation."
  echo "-u|--uninstall          Uninstall ZCS"
  echo "-x|--skipspacecheck     Skip filesystem capacity checks."
  echo "--platform-override     Allows installer to continue on an unknown OS."
  echo "--skip-upgrade-check    Allows installer to skip upgrade validation checks."
  echo "--force-upgrade         Force upgrade to be set to YES. Used if there is package installation failure for remote packages."
  echo "[defaultsfile]          File containing default install values."
  echo ""
  exit
}

while [ $# -ne 0 ]; do
  case $1 in
    -r|--restore|--config)
      shift
      RESTORECONFIG=$1
      ;;
    -u|--uninstall)
      UNINSTALL="yes"
      ;;
    -s|--softwareonly)
      SOFTWAREONLY="yes"
      ;;
    -x|--skipspacecheck)
      SKIPSPACECHECK="yes"
      ;;
    -platform-override|--platform-override)
      ALLOW_PLATFORM_OVERRIDE="yes"
      ;;
    -skip-upgrade-check|--skip-upgrade-check)
      SKIP_UPGRADE_CHECK="yes"
      ;;
    -force-upgrade|--force-upgrade)
      FORCE_UPGRADE="yes"
      UPGRADE="yes"
      ;;
    -h|-help|--help)
      usage
      ;;
    *)
      DEFAULTFILE=$1
      if [ ! -f "$DEFAULTFILE" ]; then
        echo "ERROR: Unknown option $DEFAULTFILE"
        usage
      fi
      ;;
  esac
  shift
done

. ./util/globals.sh

getPlatformVars

mkdir -p $SAVEDIR
chown zimbra:zimbra $SAVEDIR 2> /dev/null
chmod 750 $SAVEDIR

echo ""
echo "Operations logged to $LOGFILE"

if [ "x$DEFAULTFILE" != "x" ]; then
	AUTOINSTALL="yes"
else
	AUTOINSTALL="no"
fi

checkExistingInstall

if [ x$UNINSTALL = "xyes" ]; then
	askYN "Completely remove existing installation?" "N"
	if [ $response = "yes" ]; then
		REMOVE="yes"
		findUbuntuExternalPackageDependencies
		saveExistingConfig
		removeExistingInstall
	fi
	exit 1
fi

checkUser root

if [ $AUTOINSTALL = "yes" ]; then
	loadConfig $DEFAULTFILE
fi

checkRequired

installable_platform=$(cat ${MYDIR}/.BUILD_PLATFORM)

if [ x"$PLATFORM" = x"$installable_platform" -a x"${ALLOW_PLATFORM_OVERRIDE}" = "xyes" ]; then
  ALLOW_PLATFORM_OVERRIDE="no"
fi

if [ x"${ALLOW_PLATFORM_OVERRIDE}" = "xno" ]; then
  configurePackageServer
fi

checkPackages

if [ $AUTOINSTALL = "no" ]; then
  setRemove

  getInstallPackages

  if [ x"$PLATFORM" != x"$installable_platform" ]; then
    echo ""
    echo "You appear to be installing packages on a platform different"
    echo "than the platform for which they were built."
    echo ""
    echo "This platform is $PLATFORM"
    echo "Packages found: $installable_platform"
    echo "This may or may not work."
    echo ""

    if [ x"${ALLOW_PLATFORM_OVERRIDE}" = "xyes" ]; then

    	echo "Using packages for a platform in which they were not designed for"
    	echo "may result in an installation that is NOT usable. Your support"
    	echo "options may be limited if you choose to continue."
        echo "You will also be responsible for configuring the system to point"
        echo "at an appropriate package repository for third party."
    	echo ""
    	askYN "Install anyway?" "N"
    	if [ $response = "no" ]; then
    		echo "Exiting..."
    		exit 1
    	fi
    else
    	echo "Installation can not continue without manual override."
    	echo "You can override this safety check with $0 --platform-override"
    	echo ""
    	echo "WARNING: Bypassing this check may result in an install or"
    	echo "upgrade that is NOT usable."
    	echo ""
    	exit 1
    fi
  fi

  verifyExecute

else
  checkVersionMatches
  if [ $VERSIONMATCH = "no" ]; then
    if [ $UPGRADE = "yes" ]; then
      echo ""
      echo "###ERROR###"
      echo ""
      echo "There is a mismatch in the versions of the installed schema"
      echo "or index and the version included in this package"
      echo ""
      echo "Automatic upgrade cancelled"
      echo ""
      exit 1
    fi
  fi
fi


D=`date +%s`
echo "${D}: INSTALL SESSION START" >> /opt/zimbra/.install_history
installPackages

D=`date +%s`
echo "${D}: INSTALL SESSION COMPLETE" >> /opt/zimbra/.install_history

if [ x$RESTORECONFIG != "x" ]; then
	SAVEDIR=$RESTORECONFIG
fi

if [ x$SAVEDIR != "x" -a x$REMOVE = "xno" ]; then
    setDefaultsFromExistingConfig
fi

if [ $UPGRADE = "yes" ]; then
	restoreExistingConfig
	restoreCerts
  # deprecated by move of zimlets to /opt/zimbra/zimlets-deployed which isn't removed on upgrade
  #restoreZimlets
fi

if [ $SOFTWAREONLY = "yes" ]; then

	echo ""
	echo "Software Installation complete!"
	echo ""
	echo "Operations logged to $LOGFILE"
	echo ""

	exit 0
fi

#
# Installation complete, now configure
#
if [ "x$DEFAULTFILE" != "x" ]; then
	/opt/zimbra/libexec/zmsetup.pl -c $DEFAULTFILE
else
	/opt/zimbra/libexec/zmsetup.pl
fi
RC=$?
if [ $RC -ne 0 ]; then
	exit $RC
fi
