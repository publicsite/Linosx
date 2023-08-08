#!/bin/sh
#stage2 :- debootstraps a vanilla rootfs for the appropriate architecture

#enter directory containing this script
cd $(dirname $(realpath $0))

if [ "$1" = "" ]; then
	echo "Argv1: <arch>"
	echo "eg. \"i386\""
	exit
else
	THEARCH="$1"
fi

#we mount the stuff for apt
mount none -t proc /proc
mount none -t sysfs /sys
mkdir -p /dev/pts
mount none -t devpts /dev/pts

#create /dev/null and /dev/zero
mknod -m 666 /dev/null c 1 3
mknod -m 666 /dev/zero c 1 5
chown root:root /dev/null /dev/zero

#fix permissions problems
chmod -Rv 700 /var/cache/apt/archives/partial/

chown -Rv debian:debian /var/cache/apt/archives/partial/

##sudo sed -i "s/deb.devuan.org/pkgmaster.devuan.org/g" /etc/apt/sources.list

THEMIRROR="http://ftp.ports.debian.org/debian-ports"

mkdir "${PWD}/rootfs"

apt-get update

apt-get install -m -y debian-archive-keyring debian-ports-archive-keyring

apt-get install -m -y debootstrap

#for yaboot
apt-get -m -y install gcc-powerpc-linux-gnu

#for mods
apt-get -m -y install qemu-system-ppc qemu-user-static

#for building linux
apt-get -m -y install flex bison libssl3 libssl-dev

###for dooble
##apt-get -m -y install make g++ qt5-qmake qtbase5-dev libqt5charts5 libqt5charts5-dev libqt5qml5 libqt5webenginewidgets5 qtwebengine5-dev libqt5webengine5 qtwebengine5-dev-tools
###for tianocore
##apt-get -m -y install uuid-dev python3 python-is-python3 nasm

debootstrap --keyring=/usr/share/keyrings/debian-ports-archive-keyring.gpg --arch=${THEARCH} --variant=minbase --components=main,contrib,non-free-firmware --include=ifupdown unstable "${PWD}/rootfs" "${THEMIRROR}"

printf "deb %s unstable main contrib non-free-firmware\n" "${THEMIRROR}" > rootfs/etc/apt/sources.list
printf "deb-src %s unstable main contrib non-free-firmware\n" "http://ftp.debian.org//debian/" >> rootfs/etc/apt/sources.list

printf "linosx\n" > "rootfs/etc/hostname"
chmod 644 "rootfs/etc/hostname"
chown root:root "rootfs/etc/hostname"

printf "127.0.0.1\tlocalhost\n" > "rootfs/etc/hosts"
printf "127.0.1.1\tlive-hybrid-iso\n" >> "rootfs/etc/hosts"
printf "::1\t\tlocalhost ip6-localhost ip6-loopback\n" >> "rootfs/etc/hosts"
printf "ff02::1\t\tip6-allnodes\n" >> "rootfs/etc/hosts"
printf "ff02::2\t\tip6-allrouters\n" >> "rootfs/etc/hosts"
chmod 644 "rootfs/etc/hosts"
chown root:root "rootfs/etc/hosts"

#unmount stuff
umount /proc
umount /sys
umount /dev/pts