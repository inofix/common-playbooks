#!/bin/sh
#
# This script includes the post-installation tasks for:
#   Inofix base: Generic host configuration for all Inofix hosts
#
# Inofix GmbH, Reto Gantenbein, 2017
# Inofix GmbH, Michael Lustenberger, 2017
#

##
# Disable interactive debconf
export DEBIAN_FRONTEND=noninteractive
unset  DEBIAN_HAS_FRONTEND

##
# Setup inofix group/users
### TODO: do resolve this from CMDB:host.admin or the like with ssh-keys
in-target groupadd -g 1000 inofix
in-target useradd -u 10000 -G inofix -c "Michael Lustenberger" -s /bin/bash -m mic
in-target chage -d 0 mic
in-target useradd -u 10051 -G inofix -c "Reto Gantenbein" -s /bin/bash -m ganto
in-target chage -d 0 ganto


##
# apt/dpkg Tuning
echo '# Do not install recommended/suggested package dependencies' >> /target/etc/apt/apt.conf
echo 'APT::Install-Recommends "0";' >> /target/etc/apt/apt.conf
echo 'APT::Install-Suggests "0";' >> /target/etc/apt/apt.conf
echo >> /target/etc/apt/apt.conf
echo '# Mount /tmp with exec options when installing packages' >> /target/etc/apt/apt.conf
echo 'DPkg::Pre-Invoke{"mount -o remount,exec /tmp";};' >> /target/etc/apt/apt.conf
echo 'DPkg::Post-Invoke {"mount -o remount /tmp";};' >> /target/etc/apt/apt.conf


##
# Purge exim4
in-target aptitude --assume-yes purge exim4 exim4-base exim4-config exim4-daemon-light

# Install SSMTP
in-target aptitude --assume-yes install ssmtp


##
# Install VCS clients
in-target aptitude --assume-yes install subversion git

# Don't store subversion cleartext passwords
sed -i 's/^#store-password/store-passwords/' /target/etc/subversion/config


##
# Install colordiff
in-target aptitude --assume-yes install colordiff

# Fix color scheme
sed -i 's/^newtext=.*$/newtext=darkgreen/g' /target/etc/colordiffrc
sed -i 's/^oldtext=.*$/oldtext=darkred/g' /target/etc/colordiffrc
sed -i 's/^diffstuff=.*$/diffstuff=white/g' /target/etc/colordiffrc
sed -i 's/^cvsstuff=.*$/cvsstuff=blue/g' /target/etc/colordiffrc


##
# Install cfengine2 (for now we run them both)
#in-target aptitude --assume-yes install cfengine2

##
# Install cfengine3
#in-target aptitude --assume-yes install cfengine3
# copy the config files in place
#cp -r /target/usr/share/doc/cfengine3/example_config /target/var/lib/cfengine3/masterfiles
#chmod 600 /target/var/lib/cfengine3/masterfiles/*
#chmod 700 /target/var/lib/cfengine3/masterfiles
# gladly ignore the FHS in this case (cfengine is seen as a meta service)
#rm /target/var/lib/cfengine3/inputs
#mkdir /target/var/lib/cfengine3/inputs/
#cp -a /target/var/lib/cfengine3/masterfiles/* /target/var/lib/cfengine3/inputs/
# always start the services
#sed -i 's;^\(RUN_CF[A-Z]*D=\)0$;\11;' /target/etc/default/cfengine3

##
# Setup mastersync
#in-target aptitude install mastersync
