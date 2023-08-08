#!/bin/sh
#stage1 :- downloads a iso and extracts the root filesystem, then runs the later stages.

if [ "$1" = "" ]; then
	echo "Argv1: <arch>"
	echo "eg. \"i386\""
	exit
else
	THEARCH="$1"
fi

if [ "$(echo "$2" | cut -c 1-12)" != "linux-image-" ]; then
	echo "Argv2: the name of the kernel package for your architecture"
	echo "eg. \"linux-image-686\""
	exit
fi

#to extract rootfs from iso
sudo apt-get -y install squashfs-tools

#enter directory containing this script
cd $(dirname $(realpath $0))

TARGET="powerpc-linux-gnu"
linux_version="6.1.1"

thepwd="${PWD}"

ISONAME="debian-live-12.0.0-amd64-standard.iso"
wget "https://cdimage.debian.org/cdimage/release/current-live/amd64/iso-hybrid/${ISONAME}"
mkdir "${thepwd}/mountpoint"
sudo mount -o loop "${ISONAME}" "${thepwd}/mountpoint"
cp -a "${thepwd}/mountpoint/live/filesystem.squashfs" .
sudo umount "${thepwd}/mountpoint"
sudo unsquashfs -f -no-xattrs -d "${thepwd}/mountpoint" filesystem.squashfs

#create /etc/resolv.conf for the outer rootfs
cat /etc/resolv.conf | sudo tee "${thepwd}/mountpoint/etc/resolv.conf"

##stage 2 - run stage two in the outer rootfs
sudo mkdir "${thepwd}/mountpoint/workdir"
sudo cp -a stage2.sh "${thepwd}/mountpoint/workdir/"
chmod +x "${thepwd}/mountpoint/workdir/stage2.sh"
sudo chroot "${thepwd}/mountpoint" /workdir/stage2.sh "${THEARCH}"

sudo mkdir -p "${thepwd}/mountpoint/workdir/rootfs/workdir"

#copy some config files to /etc/skel in the inner rootfs
sudo mkdir -p "${thepwd}/mountpoint/workdir/rootfs/etc/skel/Desktop"
sudo mkdir -p "${thepwd}/mountpoint/workdir/rootfs/etc/skel/.config"
sudo cp -a "${thepwd}/xfce4" "${thepwd}/mountpoint/workdir/rootfs/etc/skel/.config/"
sudo cp -a "${thepwd}/.xinitrc" "${thepwd}/mountpoint/workdir/rootfs/etc/skel/"
sudo chmod 700 "${thepwd}/mountpoint/workdir/rootfs/etc/skel/.xinitrc"
sudo ln -s .xinitrc "${thepwd}/mountpoint/workdir/rootfs/etc/skel/.xsession"
sudo chmod 700 "${thepwd}/mountpoint/workdir/rootfs/etc/skel/.xsession" "${thepwd}/mountpoint/workdir/rootfs/etc/skel/.xinitrc"
sudo mkdir -p "${thepwd}/mountpoint/workdir/rootfs/etc/skel/.config/gtk-3.0"
sudo cp -a "${thepwd}/gtk-configs/gtk.css" "${thepwd}/mountpoint/workdir/rootfs/etc/skel/.config/gtk-3.0/"
sudo cp -a "${thepwd}/gtk-configs/settings.ini" "${thepwd}/mountpoint/workdir/rootfs/etc/skel/.config/gtk-3.0/"
sudo cp -a "${thepwd}/gtk-configs/.gtkrc-2.0" "${thepwd}/mountpoint/workdir/rootfs/etc/skel/"

#wallpaper for xfce
sudo cp -a "${thepwd}/TenPeaksDayMac.png" "${thepwd}/mountpoint/workdir/rootfs/"
sudo chmod a+r "${thepwd}/mountpoint/workdir/rootfs/TenPeaksDayMac.png"

#copy some config files to /root in the inner rootfs
sudo mkdir -p "${thepwd}/mountpoint/workdir/rootfs/root/Desktop"
sudo mkdir -p "${thepwd}/mountpoint/workdir/rootfs/root/.config"
sudo cp -a ${thepwd}/xfce4 "${thepwd}/mountpoint/workdir/rootfs/root/.config/"

#installer xinitrc
sudo cp -a ${thepwd}/installer.xinitrc "${thepwd}/mountpoint/workdir/rootfs/root/.xinitrc"
sudo chmod 700 "${thepwd}/mountpoint/workdir/rootfs/root/.xinitrc"

sudo ln -s .xinitrc "${thepwd}/mountpoint/workdir/rootfs/root/.xsession"
sudo chmod 700 "${thepwd}/mountpoint/workdir/rootfs/root/.xsession" "${thepwd}/mountpoint/workdir/rootfs/root/.xinitrc"
sudo mkdir -p "${thepwd}/mountpoint/workdir/rootfs/root/.config/gtk-3.0"
sudo cp -a "${thepwd}/gtk-configs/gtk.css" "${thepwd}/mountpoint/workdir/rootfs/root/.config/gtk-3.0/"
sudo cp -a "${thepwd}/gtk-configs/settings.ini" "${thepwd}/mountpoint/workdir/rootfs/root/.config/gtk-3.0/"
sudo cp -a "${thepwd}/gtk-configs/.gtkrc-2.0" "${thepwd}/mountpoint/workdir/rootfs/root/"

#copy touchpad tap-to-click xorg setting to /usr/share/X11/xorg.conf.d in the inner rootfs
sudo mkdir -p "${thepwd}/mountpoint/workdir/rootfs/usr/share/X11/xorg.conf.d"
sudo cp "${thepwd}/50-synaptics.conf" "${thepwd}/mountpoint/workdir/rootfs/usr/share/X11/xorg.conf.d/50-synaptics.conf"

#create /etc/resolv.conf for inner rootfs
cat /etc/resolv.conf | sudo tee "${thepwd}/mountpoint/workdir/rootfs/etc/resolv.conf"

###copy build scripts to inner rootfs
##sudo cp -a "${thepwd}/myBuildsHost" "${thepwd}/mountpoint/workdir/rootfs/workdir/"
##sudo cp -a "${thepwd}/helpers" "${thepwd}/mountpoint/workdir/rootfs/workdir/"
##sudo cp -a "${thepwd}/getEquiptmentHost.sh" "${thepwd}/mountpoint/workdir/rootfs/workdir/"
##sudo cp -a "${thepwd}/installEquiptmentHost.sh" "${thepwd}/mountpoint/rootfs/workdir/"
##sudo chmod +x "${thepwd}/mountpoint/workdir/rootfs/workdir/getEquiptmentHost.sh"
##sudo chmod +x "${thepwd}/mountpoint/workdir/rootfs/workdir/installEquiptmentHost.sh"

sudo cp -a "${thepwd}/mountpoint/usr/bin/qemu-ppc-static" "${thepwd}/mountpoint/workdir/rootfs/"

#run stage three in the inner rootfs
sudo cp "${thepwd}/stage3.sh" "${thepwd}/mountpoint/workdir/rootfs/workdir/"
sudo chmod +x "${thepwd}/mountpoint/workdir/rootfs/workdir/stage3.sh"
sudo chroot "${thepwd}/mountpoint/workdir/rootfs" /qemu-ppc-static /bin/sh /workdir/stage3.sh "${THEARCH}"

#copy build scripts to the outer rootfs
sudo cp -a "${thepwd}/myBuildsBuild" "${thepwd}/mountpoint/workdir"
sudo cp -a "${thepwd}/helpers" "${thepwd}/mountpoint/workdir"
sudo cp -a "${thepwd}/getEquiptmentBuild.sh" "${thepwd}/mountpoint/workdir"
sudo cp -a "${thepwd}/installEquiptmentBuild.sh" "${thepwd}/mountpoint/workdir"
sudo chmod +x "${thepwd}/mountpoint/workdir/getEquiptmentBuild.sh"
sudo chmod +x "${thepwd}/mountpoint/workdir/installEquiptmentBuild.sh"

#run build scripts in the outer rootfs
sudo chroot ${thepwd}/mountpoint /workdir/getEquiptmentBuild.sh /workdir
sudo chroot ${thepwd}/mountpoint /workdir/installEquiptmentBuild.sh /workdir




#clean up any scripts inside the inner rootfs
sudo rm -rf "${thepwd}/mountpoint/workdir/rootfs/workdir"

sudo cp -a "${thepwd}/init-overlay.sh" "${thepwd}/mountpoint/workdir/rootfs/sbin/"
sudo chmod +x "${thepwd}/mountpoint/workdir/rootfs/sbin/init-overlay.sh"
sudo cp installToHDD.sh  "${thepwd}/mountpoint/workdir/rootfs/sbin/"
sudo chmod +x "${thepwd}/mountpoint/workdir/rootfs/sbin/installToHDD.sh"

sudo mkdir "${thepwd}/mountpoint/workdir/rootfs/overlay"
sudo mkdir "${thepwd}/mountpoint/workdir/rootfs/overlay/tmpfs"
sudo mkdir "${thepwd}/mountpoint/workdir/rootfs/overlay/mountpoint"

sudo rm -rf "${thepwd}/mountpoint/workdir/rootfs/tmp/*"

##back up permissions that have sbit set to restore later upon installation
sudo echo '#!/bin/sh' | sudo tee "${thepwd}/mountpoint/workdir/getperms.sh"
sudo echo 'cd /workdir/rootfs' | sudo tee -a "${thepwd}/mountpoint/workdir/getperms.sh"
sudo echo 'getfacl -R . > saved-permissions' | sudo tee -a "${thepwd}/mountpoint/workdir/getperms.sh"
sudo chmod +x "${thepwd}/mountpoint/workdir/getperms.sh"
sudo chroot "${thepwd}/mountpoint" /workdir/getperms.sh

#getfacl -R . | tee saved-permissions


#cd "${thepwd}/mountpoint/workdir/rootfs/"
#if [ -f saved-permissions ]; then
#	sudo rm -f saved-permissions
#fi
#sudo find -depth -printf '%m:%u:%g:%p\n' | sudo tee -a "${thepwd}/mountpoint/workdir/saved-permissions"
#if [ -f "${thepwd}/mountpoint/workdir/rootfs/saved-permissions" ]; then
#	sudo rm -f "${thepwd}/mountpoint/workdir/rootfs/saved-permissions"
#fi
#sudo mv "${thepwd}/mountpoint/workdir/saved-permissions" "${thepwd}/mountpoint/workdir/rootfs/saved-permissions"
#cd "${thepwd}"



##make a yboot config
#sudo echo 'boot=/dev/hda1' | sudo tee "${thepwd}/mountpoint/workdir/rootfs/etc/yaboot.conf"
#sudo echo 'magicboot=/usr/lib/yaboot/ofboot' | sudo tee -a "${thepwd}/mountpoint/workdir/rootfs/etc/yaboot.conf"
#sudo echo 'delay=5' | sudo tee -a "${thepwd}/mountpoint/workdir/rootfs/etc/yaboot.conf"
#sudo echo 'timeout=50' | sudo tee -a "${thepwd}/mountpoint/workdir/rootfs/etc/yaboot.conf"
#sudo echo 'root=/dev/sda2' | sudo tee -a "${thepwd}/mountpoint/workdir/rootfs/etc/yaboot.conf"
#sudo echo 'device=hd:' | sudo tee -a "${thepwd}/mountpoint/workdir/rootfs/etc/yaboot.conf"
#sudo echo 'image=/vmlinuz' | sudo tee -a "${thepwd}/mountpoint/workdir/rootfs/etc/yaboot.conf"
#sudo echo '	 label=Linosx' | sudo tee -a "${thepwd}/mountpoint/workdir/rootfs/etc/yaboot.conf"
#sudo echo '	 partition=2' | sudo tee -a "${thepwd}/mountpoint/workdir/rootfs/etc/yaboot.conf"
#sudo echo '	 initrd=/boot/initrd.img-linux' | sudo tee -a "${thepwd}/mountpoint/workdir/rootfs/etc/yaboot.conf"
#sudo echo '	 append="root=/dev/sda2 console=tty0 init=/sbin/init"' | sudo tee -a "${thepwd}/mountpoint/workdir/rootfs/etc/yaboot.conf"

sudo cp -a "${thepwd}/mountpoint/workdir/rootfs" mountpoint/workdir/topack
sudo mv "${thepwd}/mountpoint/workdir/topack" mountpoint/workdir/rootfs/
sudo rm -f "${thepwd}/mountpoint/workdir/rootfs/topack/qemu-ppc-static"

echo 'menuentry "I am booting from USB" {' > "${thepwd}/grub.cfg"
echo '	linux /boot/vmlinuz-linux root=/dev/sdb1 console=tty0 init=/sbin/init-overlay.sh modprobe.blacklist=bochs_drm' >> "${thepwd}/grub.cfg"
echo '	initrd /boot/initrd.img-linux' >> "${thepwd}/grub.cfg"
echo '}' >> "${thepwd}/grub.cfg"
echo 'menuentry "I am booting from DVD" {' >> "${thepwd}/grub.cfg"
echo '	linux /boot/vmlinuz-linux root=/dev/sr0 console=tty0 init=/sbin/init-overlay.sh modprobe.blacklist=bochs_drm' >> "${thepwd}/grub.cfg"
echo '	initrd /boot/initrd.img-linux' >> "${thepwd}/grub.cfg"
echo '}' >> "${thepwd}/grub.cfg"
sudo mkdir -p "${thepwd}/mountpoint/workdir/rootfs/topack/boot/grub"
sudo mv "${thepwd}/grub.cfg" "${thepwd}/mountpoint/workdir/rootfs/topack/boot/grub/grub.cfg"

sudo chroot "${thepwd}/mountpoint/workdir/rootfs" /qemu-ppc-static /usr/bin/grub-mkrescue -o linosx-powerpc.iso /topack

sudo mv "${thepwd}/mountpoint/workdir/rootfs/linosx-powerpc.iso" "${thepwd}/"

sudo rm -rf "${thepwd}/mountpoint/workdir/rootfs/topack"