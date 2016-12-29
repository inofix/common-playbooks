#!/bin/sh
#
# This script will be called after the standard Debian Preseed installation
# is finished. After some generic tasks, the postinstall.sh scripts of the
# choosen classes (if any) are executed.
#
# Inofix GmbH, Reto Gantenbein, 2013
#
exit
# Work around some annoying dpkg hangs in chroot
export DEBIAN_FRONTEND=noninteractive
unset  DEBIAN_HAS_FRONTEND
unset  DEBCONF_REDIR
unset  DEBCONF_OLD_FD_BASE

# First fetch and run the generic Debian post-installation script
preseed_fetch ps/debian_postinstall.sh /tmp/debian_postinstall.sh
log-output -t debian_postinstall sh /tmp/debian_postinstall.sh

# Fetch and run class specific post-installation scripts
classes=$(debconf-get auto-install/classes | sed 's/,/ /g')
if [ -n "${classes}" ]; then
	for class in ${classes}; do
		preseed_fetch ps/classes/${class}/class_script.sh /tmp/${class}_script.sh
		log-output -t ${class}_script sh /tmp/${class}_script.sh
	done
fi
