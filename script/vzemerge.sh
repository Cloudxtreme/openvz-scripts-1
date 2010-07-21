#!/bin/sh

# Checking if its ran by root.
ROOT_UID=0
E_NOTROOT=67
E_NOARGS=1
E_FORBIDDEN=1

echo
echo
echo
echo "UPDATE THIS SCRIPT to take care of make.profiles in each vm container"
echo
echo
echo
exit 1


if [ "$UID" -ne "$ROOT_UID" ]
then
	echo "Must be root to run this container update script."
	exit $E_NOTROOT
fi

# Checking if there is enough command line args
if [[ $# -le 1 ]]
then
	echo "Must have atleast the VZ container id and emerge command line args."
	echo "vzemerge <VEID> <emerge args>"
	exit $E_NOARGS
fi

# Cleaning up the args
VEID=$1
EMERGECMD=''
for command in "$@"
do
	if [[ $command -ne $VEID ]]
	then
		EMERGECMD="$EMERGECMD $command"
	fi
done

# Checking to see if it isn't the forbidden vz container
FORBIDDEN=600
if [[ $VEID -eq $FORBIDDEN ]]
then
	echo "It is container 600, which hosts the rsync daemon and portage, this is forbidden to run this script on this container!"
	exit $E_FORBIDDEN
fi

echo "Seting up the environment for executing emerge in the container."
mount -o bind /usr/portage/ /vz/root/$VEID/usr/portage/
sleep 1

echo "Running emerge."
vzctl exec $VEID emerge $EMERGECMD
sleep 1

echo "Cleaning up the environment inside the container."
umount /vz/root/$VEID/usr/portage/
sleep 1
