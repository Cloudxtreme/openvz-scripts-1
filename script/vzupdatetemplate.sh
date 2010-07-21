#!/bin/sh

# Checking if its ran by root
ROOT_UID=0
if [ "$UID" -ne "$ROOT_UID" ]
then
    echo "Must be root to run this container update script."
    exit 67
fi

# Making sure the /tmp/vz_template directory does not already exist
if [ -d "/tmp/vz_template" ]
then
    echo "Please get rid of /tmp/vz_template" first
#    exit 1
fi


# changedir to /tmp where we will be doing all our work
cd /tmp

# Fetch the "latest template" textfile
#LATEST_STAGE='http://mirrors.kernel.org/gentoo/releases/amd64/autobuilds/'
LATEST_STAGE='http://distfiles.gentoo.org/releases/amd64/autobuilds/'
LATEST_TXT='latest-stage3.txt'

STAGE=$(wget -q -O - "$LATEST_STAGE$LATEST_TXT" | tail -n1)

# Extracting filename out of the path
FILENAME=$(basename "$STAGE")

echo "Downloading stage: $FILENAME"

# When done testing remove the "-nc" --no-clobber
# When done testing remove the "-nv" --no-verbose
wget -P '/tmp' "$LATEST_STAGE$STAGE"
wget -P '/tmp' "$LATEST_STAGE$STAGE.DIGESTS"

# Capture the output of sha1sum check
echo "Checking the digest"
CHECKSUM=$(sha1sum -c /tmp/$FILENAME.DIGESTS 2>&1)

if [[ $CHECKSUM != *OK* ]]
then
    echo "Checksum failed, please re-run this script or verify the downloaded stage3 file manually."
    exit 1
fi

# Checksum has passed so time to process the stage3.bz2 file
echo "Extracting the stage3 bzip file for processing..."


mkdir /tmp/vz_template
tar -xjpf "/tmp/$FILENAME" -C /tmp/vz_template

echo "Processing the contents of the stage3 bzip..."

#
# http://wiki.openvz.org/Gentoo_template_creation
#

# Symlink /etc/mtab to /proc/mounts
if [ -f /tmp/vz_template/etc/mtab ]
then
    rm -f /tmp/vz_template/etc/mtab
fi

ln -s /proc/mounts /tmp/vz_template/etc/mtab


# Replace /etc/fstab
echo "proc  /proc   proc    defaults 0 0" > /tmp/vz_template/etc/fstab
# Gentoo Specific
echo "shm	    /dev/shm	tmpfs	    nodev,nosuid,noexec	0 0" >> /tmp/vz_template/etc/fstab


# Edit the initab
sed 's/^c.*getty.*/#&/g' /tmp/vz_template/etc/inittab > /tmp/tmp_inittab && mv /tmp/tmp_inittab /tmp/vz_template/etc/inittab


# Disable root password
sed 's/^root:\*:/root:!:/g' /tmp/vz_template/etc/shadow > /tmp/tmp_shadow && mv /tmp/tmp_shadow /tmp/vz_template/etc/shadow


# Disable unneeded init scripts
INITD="checkroot checkfs keymaps consolefont numlock"

for ARG in /tmp/vz_template/etc/runlevels/*
do
    for SCRIPTS in $INITD
    do
	if [ -f "$ARG/$SCRIPTS" ]
	then
	    rm -f -- "$ARG/$SCRIPTS"
	fi
    done
done


# Disable the mounting of the /sys
sed 's/try mount -n ${mntcmd:--t sysfs sysfs \/sys -o noexec,nosuid,nodev}/#&/g' /tmp/vz_template/sbin/rc > /tmp/tmp_rc && mv /tmp/tmp_rc /tmp/vz_template/sbin/rc


# Updating the /etc/make.conf file
sed 's/USE=.*/USE="-* nptl nptlonly crypt pam ssl tcpd unicode mmx sse sse2 nls ipv6"/g' /tmp/vz_template/etc/make.conf > /tmp/tmp_make && mv /tmp/tmp_make /tmp/vz_template/etc/make.conf

cat >> /tmp/vz_template/etc/make.conf <<EOF
CONFIG_PROTECT="/sbin/rc"
MAKEOPTS="-j2"
FEATURES="sandbox distlocks fixpackages userfetch userpriv usersandbox"
LANG="en_US.UTF-8"
LINGUAS="en_US en"
EOF


# Wiki says its good idea to set RC_DEVICES to static, but none of the VM has any ill effects so far...
# Going to leave this part alone


# Create a portage dir in the usr directory
mkdir /tmp/vz_template/usr/portage


# Create empty /etc/portage directory and fill it with empty portage.* files - Purely for lazyness
mkdir /tmp/vz_template/etc/portage
touch /tmp/vz_template/etc/portage/package.keywords
touch /tmp/vz_template/etc/portage/package.mask
touch /tmp/vz_template/etc/portage/package.unmask
touch /tmp/vz_template/etc/portage/package.use


# Finished hacking away at the container, repack it up
echo "Repacking the stage3 folder into a tar.gz..."

NEW_FILENAME=$(echo "$FILENAME" | sed -e 's/\.bz2$/\.gz/g')

cd /tmp/vz_template
tar -czpf "/tmp/$NEW_FILENAME" *
cd /tmp

echo "Moving the new stage3 tar.gz into the OpenVZ Template cache..."


# Cleaning up after ourselves
#rm -- "$FILENAME"
#rm -- "$FILENAME.DIGESTS"
