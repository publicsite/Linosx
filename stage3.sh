#!/bin/sh
#stage3 :- customises a vanilla rootfs

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

chown -Rv _apt:root /var/cache/apt/archives/partial/

export DEBIAN_FRONTEND=noninteractive
export LC_ALL=C
export LANG=C
export LANGUAGE=C

apt-get --allow-unauthenticated update 
apt-get --allow-unauthenticated -m -y install debian-ports-archive-keyring debian-archive-keyring
apt-get update

#this stuff doesn't like chroots, so we get rid of it for the purposes of building
apt-get -y autoremove  exim4-config exim4-base exim4-daemon-light exim4-config-2 exim4

#update the system
apt-get -y update && apt-get -y upgrade



apt-get -m -y install \
task-laptop \
task-english \
alsa-utils \
init \
systemd-sysv \
live-config \
console-setup-mini \
xdg-utils \
xorg \
xserver-xorg-input-all \
xserver-xorg-video-amdgpu \
xserver-xorg-video-ati \
xserver-xorg-video-dummy \
xserver-xorg-video-vesa \
xserver-xorg-video-qxl \
xserver-xorg-video-fbdev \
va-driver-all xfwm4 \
pulseaudio \
xfce4-panel \
xfce4-pulseaudio-plugin \
xfce4-terminal \
xfce4-whiskermenu-plugin \
thunar \
thunar-archive-plugin \
xdm \
blueman \
qalculate-gtk \
xfburn \
mousepad \
pavucontrol \
evince \
gparted \
htop \
firmware-linux-free \
grub2 \
xorriso \
tiny-initramfs \
hfsutils \
mac-fdisk \
acl \
epiphany-browser

apt-get -m -y install --no-install-recommends \
pciutils \
bc \
breeze-icon-theme \
wget \
nano \
file \
iputils-ping \
fonts-crosextra-caladea \
fonts-crosextra-carlito \
fonts-liberation2 \
fonts-linuxlibertine \
fonts-noto-core \
fonts-noto-extra \
fonts-noto-ui-core \
fonts-sil-gentium-basic \
xfdesktop4 \
xfdesktop4-data \
locales \
whois \
telnet \
aptitude \
lsof \
time \
tnftp \
xserver-xorg-input-mouse \
xserver-xorg-input-synaptics \
sudo \
fdisk \
less \
xfce4-session \
connman \
connman-gtk \
xfce4-power-manager \
xfce4-power-manager-plugins \
dns323-firmware-tools \
firmware-linux-free \
hdmi2usb-fx2-firmware \
sigrok-firmware-fx2lafw \
bluez-firmware \
dahdi-firmware-nonfree \
firmware-amd-graphics \
firmware-atheros \
firmware-bnx2 \
firmware-bnx2x \
firmware-brcm80211 \
firmware-cavium \
firmware-intel-sound \
firmware-iwlwifi \
firmware-libertas \
firmware-linux \
firmware-linux-nonfree \
firmware-misc-nonfree \
firmware-myricom \
firmware-netronome \
firmware-netxen \
firmware-qcom-media \
firmware-qlogic \
firmware-realtek \
firmware-samsung \
firmware-siano \
firmware-ti-connectivity \
firmware-zd1211 \
tzdata \
greybird-gtk-theme \
libext2fs2 libext2fs-dev \
ntpsec

##not needed because we use hfsutils for formatting instead
##wget http://ftp.ports.debian.org/debian-ports/pool-powerpc/main/h/hfsprogs/hfsprogs_540.1.linux3-5+ports_powerpc.deb
##dpkg -i hfsprogs_540.1.linux3-5+ports_powerpc.deb

##not needed because grub2 works fine
##wget "http://ftp.ports.debian.org/debian-ports/pool-powerpc/main/y/yaboot/yaboot_1.3.17-4+ports1_powerpc.deb"
##dpkg -i yaboot_1.3.17-4+ports1_powerpc.deb

echo "TYPE PASSWORD FOR: root"
passwd root

echo "TYPE PASSWORD FOR: user"
adduser user

gpasswd -a user sudo
/usr/sbin/groupadd power
gpasswd -a user power
gpasswd -a user users
gpasswd -a user bluetooth
gpasswd -a user plugdev
gpasswd -a user video
/usr/sbin/groupadd lpadmin
gpasswd -a user lpadmin

if [ "$(grep "%users ALL = NOPASSWD:/usr/lib/${THEARCH}-linux-gnu/xfce4/session/xfsm-shutdown-helper" /etc/sudoers)" = "" ]; then
	echo "" >> /etc/sudoers
	echo "# Allow members of group sudo to execute any command" >> /etc/sudoers
	echo "%sudo   ALL=(ALL:ALL) ALL" >> /etc/sudoers
	echo "" >> /etc/sudoers
	echo "# Allow anyone to shut the machine down" >> /etc/sudoers
	echo "%users ALL = NOPASSWD:/usr/lib/${THEARCH}-linux-gnu/xfce4/session/xfsm-shutdown-helper" >> /etc/sudoers
fi

if [ -f "rootfs/usr/share/X11/xorg.conf.d/40-libinput.conf" ]; then
	#delete this because we will write to it
	if [ -f "rootfs/etc/X11/xorg.conf.d/40-libinput.conf" ]; then
	rm "rootfs/etc/X11/xorg.conf.d/40-libinput.conf"
	fi
	OLD_IFS="$IFS"
	IFS="$(printf "\n")"
	cat "rootfs/usr/share/X11/xorg.conf.d/40-libinput.conf" | while read line; do
		if [ "$line" = "        Identifier \"libinput touchpad catchall\"" ]; then
			echo "$line" >> "rootfs/etc/X11/xorg.conf.d/40-libinput.conf"
			echo "        Option \"Tapping\" \"on\"" >> "rootfs/etc/X11/xorg.conf.d/40-libinput.conf"
		else
			echo "$line" >> "rootfs/etc/X11/xorg.conf.d/40-libinput.conf"
		fi
	done
	IFS="$OLD_IFS"
fi

apt-get clean

#cd /workdir
#/workdir/getEquiptmentHost.sh /workdir
#/workdir/installEquiptmentHost.sh /workdir

rm /etc/resolv.conf
rm -rf /tmp/*

mkdir -p /sys/fs/cgroup

/usr/sbin/update-tirfss

chown -R user:user /home/user
chmod -R u+w /home/user
chmod -R u+r /home/user

chown -R root:root /etc/skel
chmod -R u+w /etc/skel
chmod -R u+r /etc/skel

chmod 755 /bin/su
chmod u+s /bin/su

cd /

ln -s boot/initrd.img-linux initrd.img

rm /root/.bash_history

#unmount stuff
umount /proc
umount /sys
umount /dev/pts
