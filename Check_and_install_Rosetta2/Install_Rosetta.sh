#!/bin/zsh

#title          :Install_Rosetta.sh
#description    :This script checks if Rosetta2 needs to be installed.
#author         :Fabian Hartmann
#date           :2020-11-23
#version        :0.1
#============================================================================

#============================================================================
### Revision History:
##
##	Date	      Version			Personnel			    Notes
##	----	      -------			----------------	-----
##	2020-11-23	  0.1			  Fabian Hartmann   Script created
#============================================================================
#
# uncoment to enable debug
#set -x

SCRIPT_NAME=`basename "${0}"`
SCRIPT_PATH=`dirname "${0}"`
loggedInUser=$(python -c 'from SystemConfiguration import SCDynamicStoreCopyConsoleUser; import sys; username = (SCDynamicStoreCopyConsoleUser(None, None, None) or [None])[0]; username = [username,""][username in [u"loginwindow", None, u""]]; sys.stdout.write(username + "\n");')
loggedInUserHome=$( dscl . read /Users/$loggedInUser NFSHomeDirectory | awk '{print $NF}' )

# get prefernces for logging
GlobalLog=$(python -c 'import CoreFoundation; print CoreFoundation.CFPreferencesCopyAppValue("LogGlobal","ch.appfruit.scriptlog");')

# get os versions
osvers_major=$(/usr/bin/sw_vers -productVersion | awk -F. '{print $1}')
osvers_minor=$(/usr/bin/sw_vers -productVersion | awk -F. '{print $2}')
osvers_dot_version=$(/usr/bin/sw_vers -productVersion | awk -F. '{print $3}')

# Name of the Log File
logfilename="Jamf_$SCRIPT_NAME.log"
# Log to a File if true
logtofile="true"

function mylogger() {
  logtext="${@}"
  if [[ -w /var/log/ ]]; then
    logpath="/var/log/"
  else
    logpath="$LoggedInUserHome/Library/Logs/"
  fi
  logfile=$logpath$logfilename
  if [[ $logtofile == "true" ]] || [[ $GlobalLog == "True" ]]; then
    echo $(date "+%b %e %H:%M:%S") $SCRIPT_NAME[]: $logtext >> $logfile
    #echo $(date "+%b %e %H:%M:%S") $SCRIPT_NAME[]: $logtext
    logger -i -t $SCRIPT_NAME "$logtext"
  fi
  if [[ $logtooutput == "true" ]] || [[ $GlobalLog == "True" ]]; then
    echo $(date "+%b %e %H:%M:%S") $SCRIPT_NAME[]: $logtext
  fi
}

# Check to see if the Mac is reporting itself as running macOS 11
if [[ ${osvers_major} -ge 11 ]]; then
  # Check to see if the Mac needs Rosetta installed by testing the processor
  processor=$(/usr/sbin/sysctl -n machdep.cpu.brand_string | grep -o "Intel")
  if [[ -n "$processor" ]]; then
    mylogger "$processor processor installed. No need to install Rosetta."
  else
    # Check Rosetta LaunchDaemon. If no LaunchDaemon is found,
    # perform a non-interactive install of Rosetta.
    if [[ ! -f "/Library/Apple/System/Library/LaunchDaemons/com.apple.oahd.plist" ]]; then
      /usr/sbin/softwareupdate -install-rosetta -agree-to-license
      if [[ $? -eq 0 ]]; then
        mylogger "Rosetta has been successfully installed."
      else
        mylogger "Rosetta installation failed!"
        exitcode=1
      fi
    else
      mylogger "Rosetta is already installed. Nothing to do."
    fi
  fi
else
  mylogger "Mac is running macOS $osvers_major.$osvers_minor.$osvers_dot_version."
  mylogger "No need to install Rosetta on this version of macOS."
fi
exit $exitcode
