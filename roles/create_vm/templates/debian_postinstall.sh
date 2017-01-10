#!/bin/sh
#
# Generic post-installation tasks after setting up a Debian VM. The
# newly installed host file system is available under /target.
#
# Inofix GmbH, 2017, Reto Gantenbein
#

# Set root password to expired
in-target chage -d 0 root

# Remove spare 'delete_me' logical volume
umount /dev/system/delete_me
lvchange -an system/delete_me
lvremove -f system/delete_me
sed -i '/^.*delete_me.*$/d' /target/etc/fstab

# Disable ctrl+alt+delete restart command
sed -i 's/^ca/#ca/g' /target/etc/inittab

# Set default runlevel 3
sed -i 's/^id:2/id:3/g' /target/etc/inittab

# Enable /dev/ttyS0 for virsh console
sed -i 's!^#T0:23:respawn:/sbin/getty -L ttyS0 9600!T0:23:respawn:/sbin/getty -L ttyS0 115200!' /target/etc/inittab

# Disable ipv6
echo 'net.ipv6.conf.all.disable_ipv6 = 1' > /target/etc/sysctl.d/01-disable-ipv6.conf

# Network hardening in sysctl.conf
sed -i 's/^#net.ipv4.conf.default.rp_filter.*/net.ipv4.conf.default.rp_filter=1/g' /target/etc/sysctl.conf
sed -i 's/^#net.ipv4.conf.all.rp_filter.*/net.ipv4.conf.all.rp_filter=1/g' /target/etc/sysctl.conf
sed -i 's/^#net.ipv4.conf.all.accept_redirects.*/net.ipv4.conf.all.accept_redirects = 0/g' /target/etc/sysctl.conf
sed -i 's/^#net.ipv4.conf.all.send_redirects.*/net.ipv4.conf.all.send_redirects = 0/g' /target/etc/sysctl.conf
sed -i 's/^#net.ipv4.conf.all.accept_source_route.*/net.ipv4.conf.all.accept_source_route = 0/g' /target/etc/sysctl.conf

# Disable nfs-related services (rpcbind, nfs-common)
in-target update-rc.d rpcbind disable
in-target update-rc.d nfs-common disable

# Enable grub serial access for virsh console
sed -i 's/^\(GRUB_CMDLINE_LINUX=.*\)"$/GRUB_CMDLINE_LINUX="console=tty0 console=ttyS0,115200n8"/g' /target/etc/default/grub
sed -i '/GRUB_CMDLINE_LINUX=/ a GRUB_SERIAL_COMMAND="serial --unit=0 --speed=115200 --word=8 --parity=no --stop=1"' /target/etc/default/grub
sed -i 's/^#GRUB_TERMINAL=.*/GRUB_TERMINAL="console serial"/g' /target/etc/default/grub
echo >> /target/etc/default/grub
echo "# Don't probe every partition for other operating systems" >> /target/etc/default/grub
echo "GRUB_DISABLE_OS_PROBER=true" >> /target/etc/default/grub
in-target grub-mkconfig -o /boot/grub/grub.cfg

# Fix SSH X11 forwarding (for wheezy)
sed -i '/X11Forwarding/ a X11UseLocalhost no' /target/etc/ssh/sshd_config

# Various logrotate configurations
sed -i 's/^rotate .*/rotate 52/g' /target/etc/logrotate.conf
sed -i 's/^#compress/compress/g' /target/etc/logrotate.conf
sed -i '/^# create/ i # add a date extension like YYYYMMDD instead of simply adding a number\ndateext\n' /target/etc/logrotate.conf

# Set the time when ntpd starts
sed -i "s/^NTPD_OPTS=.*$/NTPD_OPTS='-g -x'/g" /target/etc/default/ntp
