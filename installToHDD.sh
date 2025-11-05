#!/bin/sh

OLD_UMASK="$(umask)"
umask 0022

thefdisk="/sbin/mac-fdisk"
thechroot="/usr/sbin/chroot"
themkfsext2="/sbin/mkfs.ext2"

mkdir /tmp/installToHDD
cd /tmp/installToHDD
thepwd="${PWD}"

THELABEL="$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 13 ; echo '')"

echo "The label will be ${THELABEL}."

THEPARTITION=""
PARTITIONNUMBER=""

if [ "$1" = "" ]; then
echo "Arg1 device to install onto eg. /dev/sdb"
exit
fi

#SECTION: TIMEZONE ...

printRegions(){
	find "/usr/share/zoneinfo" -maxdepth 1 -mindepth 1 -type d | while read line; do
		line="$(basename "$line")"
		if [ "${line}" != "posix" ] && [ "${line}" != "right" ]; then
			echo "${line}"
		fi
	done
}

check_for_region(){
		printRegions | while read line; do
			if [ "$1" = "${line}" ]; then
				echo "found"
				break
			fi
		done
}


printZones(){
	find "/usr/share/zoneinfo/${1}" -maxdepth 1 -mindepth 1 -type f | while read line; do
		line="$(basename "$line")"
		if [ "${line}" != "posix" ] && [ "${line}" != "right" ]; then
			echo "${line}"
		fi
	done
}

check_for_zone(){
		printZones "${2}" | while read line; do
			if [ "$1" = "${line}" ]; then
				echo "found"
				break
			fi
		done
}
set_timezone(){
while true; do
		echo "Type \"L\" to see regions. Or type a region or, otherwise type \"C\" for cancel.\n"
		read option12
	if [ "${option12}" = "L" ] || [ "${option12}" = "l" ]; then
		printRegions "${1}" | less
	elif [ "${option12}" = "C" ] || [ "${option12}" = "c" ]; then
		echo ""
		echo "***Not setting timezone.***"
		echo ""
		break
	else
		if [ "$(check_for_region "${option12}")" = "found" ]; then
				while true; do
				echo "Type \"L\" to see zones. Or type a zone or, otherwise type \"C\" for cancel.\n"
					read option13
					if [ "${option13}" = "L" ] || [ "${option13}" = "l" ]; then
						printZones "${option12}" | less
					elif [ "${option13}" = "C" ] || [ "${option13}" = "c" ]; then
						echo ""
						echo "***Not setting timezone.***"
						echo ""
						break
					else
						if [ "$(check_for_zone "${option13}" "${option12}")" = "found" ]; then
							echo "Setting timezone to ${option12}/${option13} ..."
							ln -sf "/usr/share/zoneinfo/${option12}/${option13}" "${1}/etc/localtime"
							break
						fi
					fi
				done
			break
		fi
	fi
done
}

#SECTION: LOCALE ...

printListOfLocales(){
	off="true"
	OLD_IFS="$IFS"
	IFS='\n'
	cat "${1}/etc/locale.gen" | while read line; do
		if [ "$line" = "" ]; then
			off="false"
		else
			if [ "$off" = "false" ]; then
				echo "${line}" | cut -d " " -f 2
			fi
		fi

	done
	IFS="$OLD_IFS"
}

check_for_locale(){
		printListOfLocales "$1" | while read line; do
			if [ "$2" = "${line}" ]; then
				echo "found"
				break
			fi
		done
}

set_locale(){
while true; do
		echo "Type \"L\" to see locales. Or type a locale or, otherwise type \"C\" for cancel.\n"
		read option7
	if [ "${option7}" = "L" ] || [ "${option7}" = "l" ]; then
		printListOfLocales "${1}" | less
	elif [ "${option7}" = "C" ] || [ "${option7}" = "c" ]; then
		echo ""
		echo "***Not setting locale.***"
		echo ""
		break
	else
		if [ "$(check_for_locale "${1}" ${option7})" = "found" ]; then
			sed -i "s/^# ${option7} /${option7} /g" "${1}/etc/locale.gen"
			${thechroot} "${1}" /usr/sbin/locale-gen
			${thechroot} "${1}" /usr/sbin/update-locale LANG="${option7}"
			break
		fi
	fi
done
}

#SECTION: KEYBOARD LAYOUT
printListOfKeymaps(){
	off="true"
	OLD_IFS="$IFS"
	IFS='\n'
	cat "${1}/usr/share/X11/xkb/rules/base.lst" | while read line; do
		if [ "$line" = "$2" ]; then
			off="false"
		else
			if [ "$off" = "false" ]; then
				if [ "$line" = "" ]; then
					break
				else
					if [ "$3" = "" ]; then
						printf ""
						echo "${line}"
					else
						thelinecut="$(echo "${line}" | sed "s/  /\t/g" | sed "s/\t /\t/g" | tr -s "\t")"
						if [ "$(echo "$thelinecut" | cut -f 3- | grep "^${3}\:.*")" != "" ]; then
							echo "${line}"
						fi
					fi
				fi
			fi
		fi

	done
	IFS="$OLD_IFS"
}

check_for_layout(){
		OLD_IFS="$IFS"
		IFS='\n'
		printListOfKeymaps "$1" "$3" | sed "s/  /\t/g" | sed "s/\t /\t/g" | tr -s "\t" | while read line; do
			if [ "$2" = "$(echo ${line} | cut -f 2)" ]; then
				echo "found"
				break
			fi
		done
		IFS="$OLD_IFS"
}

choose_layout(){
while true; do
		printf "*** Type \"L\" to see keyboard layouts. ***\n"
		printf "*** Type a layout code to set a layout, ***\n"
		printf "*** Or otherwise type \"C\" to not bother setting a layout. ***\n"
		read option8
	if [ "${option8}" = "L" ] || [ "${option8}" = "l" ]; then
		printf "*** (Press q to exit list) ***\n%s" "$(printListOfKeymaps "${1}" "! layout")" | less
	elif [ "${option8}" = "C" ] || [ "${option8}" = "c" ]; then
		echo ""
		printf "***Not setting keyboard layout.***"
		echo ""
		break
	else
		if [ "$(check_for_layout "${1}" "${option8}" "! layout")" = "found" ]; then
			printf "Setting layout to %s.\n\n" "${option8}"
			sed -i 's/XKBLAYOUT=\"\w*"/XKBLAYOUT=\"'${option8}'\"/g' "${1}/etc/default/keyboard"
			keymaps=""
			while true; do
					printf "*** Please wait while I print your variants for %s ***\n" "${option8}"
					printf "*** Then, type a variant code ***\n"
					printf "*** Or otherwise type \"C\" to not bother setting a keyboard variant ***\n"
					if [ "$keymaps" = "" ]; then
						keymaps="$(printListOfKeymaps "${1}" "! variant" "${option8}")"
					fi
					printf "%s\n" "$keymaps"
					read option9
				if [ "${option9}" = "C" ] || [ "${option9}" = "c" ]; then
					echo ""
					printf "***Not setting keyboard variant.***"
					echo ""
					break
				elif [ "$(check_for_layout "${1}" "${option9}" "! variant")" = "found" ]; then
					printf "Setting variant to %s.\n\n" "${option9}"
					sed -i 's/XKBVARIANT=\"\w*"/XKBVARIANT=\"'${option9}'\"/g' "${1}/etc/default/keyboard"
					break
				fi
			done
			break
		fi
	fi
done
}

hfs_partition(){
	while true; do
		echo "Would you like to format the drive[Y/N]?"
		read option10
		if [ "${option10}" = "Y" ] || [ "${option10}" = "y" ]; then
			echo ""
			echo "***Formatting drive.***"
			echo ""

			#printf "o\nn\np\n1\n\n+256M\nt\naf\nw" | ${thefdisk} ${1}
			printf "i\n\nb\n1\nw\ny\nq\n" | ${thefdisk} ${1}
			printf "C\n64\n256M\nApple_Bootstrap\nApple_Bootstrap\nw\ny\nq\n"  | ${thefdisk} ${1}
			printf "c\n3P\n3P\nLinosx\nw\ny\nq\n" | ${thefdisk} ${1}

			#mkofboot -v

			hformat ${1}2

			#ybin -v

			#make the grub config
			#echo 'menuentry "Linosx" {' > "grub.cfg"
			echo 'set root='ieee1275/ide0,apple3'' >> "grub.cfg"
			echo '	linux /vmlinuz root=/dev/sda3 console=tty0 init=/sbin/init modprobe.blacklist=bochs_drm rw' >> "grub.cfg"
			echo '	initrd /initrd.img' >> "grub.cfg"
			echo 'boot' >> "grub.cfg"
			#echo '}' >> "grub.cfg"

			grub-mkimage -c grub.cfg -o tbxi -O powerpc-ieee1275 -C xz -p /usr/lib/grub/powerpc-ieee1275/*.mod

			hmount ${1}2
			hcopy tbxi :tbxi
			hattrib -t tbxi :tbxi
			hattrib -b :
			humount ${1}2

			"${themkfsext2}" "/dev/sda3" -L "Linosx"

				

			#mkdir mountpoint

			#mount ${1}1 mountpoint
			##mkdir mountpoint/ppc
			##cp -a /usr/lib/grub/powerpc-ieee1275/bootinfo.txt mountpoint/ppc/
			##sed -i "s#\\\boot\\\grub\\\powerpc.elf#\\\boot\\\grub\\\powerpc-ieee1275\\\core.elf#g" mountpoint/ppc/bootinfo.txt

			#mkdir mountpoint/boot
			#grub-install --boot-directory mountpoint/boot

			##make the grub config
			#echo 'menuentry "Linosx" {' > "mountpoint/boot/grub/grub.cfg"
			#echo '	linux /vmlinuz root=/dev/sda2 console=tty0 init=/sbin/init modprobe.blacklist=bochs_drm' >> "mountpoint/boot/grub/grub.cfg"
			#echo '	initrd /initrd.img' >> "mountpoint/boot/grub/grub.cfg"
			#echo '}' >> "mountpoint/boot/grub/grub.cfg"

			#mkdir mountpoint/boot
			#cp -a /boot/vmlinuz-linux mountpoint/vmlinuz
			#cp -a /boot/initrd.img-linux mountpoint/initrd.img

			#umount mountpoint

			#hmount ${1}1
			###hcopy tbxi :tbxi
			#hattrib -t tbxi :boot:grub:grub
			#hattrib -b :
			#humount ${1}1


			echo ""
			break
		elif [ "${option10}" = "N" ] || [ "${option10}" = "n" ]; then
			echo ""
			echo "***Not formatting drive.***"
			echo ""
			break
		fi
	done
}

are_you_sure(){
while true; do
		if [ "$3" = "deletepartition" ]; then
			echo "Are you sure you would like to delete ${1}${2} [Y/N]?"
		fi
		read option3
	if [ "${option3}" = "Y" ] || [ "${option3}" = "y" ]; then
		if [ "$3" = "deletepartition" ]; then
(
echo d # Delete a partition
echo ${2} #Partition number
echo w #Write
echo y #Confirm
echo q #Quit
) | ${thefdisk} ${1}

			echo ""
			echo "***Partition ${1}${2} deleted.***"
			echo ""
			break
		fi
	elif [ "${option3}" = "N" ] || [ "${option3}" = "n" ]; then
		echo ""
		echo "***Partition NOT deleted.***"
		echo ""
		break
	fi
done
}

delete_partition (){
while true; do
		printf "p\nq\n" | ${thefdisk} "$1"
		echo ""
		echo "Enter partition number to delete or enter C for cancel."
		read option2
	if [ "${option2}" = "C" ] || [ "${option2}" = "c" ]; then
		break;
	else
		if [ -b "${1}${option2}" ]; then
			are_you_sure "$1" "${option2}" deletepartition
			break
		fi
	fi
done
}

create_filesystem (){
while true; do
		printf "p\nq\n" | ${thefdisk} "$1"
		echo ""
		echo "Enter partition number to create filesystem on, or enter D for done."
		read option2
	if [ "${option2}" = "D" ] || [ "${option2}" = "d" ]; then
		break;
	else
		if [ -b "${1}${option2}" ]; then
			are_you_sure "$1" "${option2}" createfilesystem
			break
		fi
	fi
done
}

while true; do
printf "p\nq\n" | ${thefdisk} "$1"
echo ""
echo "Would you like to:"
echo "1) Delete a partition"
echo "2) Format the disk"
echo "3) Next"
read option11
	if [ "${option11}" = 1 ]; then
		delete_partition "$1"
	elif [ "${option11}" = 2 ]; then
		hfs_partition "$1"
	elif [ "${option11}" = 3 ]; then
		break
	fi
done

THEPARTITION="/dev/sda3"

mkdir tempmount

mount "$THEPARTITION" tempmount

echo "*** Copying the files ***"

#copy the files
dest="${thepwd}/tempmount"
cd /
find . -maxdepth 1 -mindepth 1 -type d | cut -c 2- | while read line; do mkdir -p ${dest}${line}; chmod --reference=.${line} ${dest}${line}; chown --reference=.${line} ${dest}${line}; done
find . -maxdepth 1 -mindepth 1 -type b,c,l,p,f | cut -c 2- | grep -v "^/swapfile\|^/.cache\|^/overlay" | while read line; do cp -a .${line} ${dest}${line}; done
find . -maxdepth 2 -mindepth 2 | cut -c 2- | grep -v "^/isolinux/*\|^/swapfile\|^/overlay/*\|^/dev/*\|^/proc/*\|^/sys/*\|^/tmp/*\|^/run/*\|^/mnt/*\|^/media/*\|^/lost+found" | while read line; do cp -a .${line} ${dest}${line}; done
cd "$dest"

#restore permissions
echo "Setting permissions ..."
setfacl --restore=saved-permissions 2>/dev/null
echo "Permissions all set."
#while IFS=: read -r mod user group file; do
#	if [ -f "$file" ] || [ -d "$file" ] ; then
#		echo "Processing permissions for $file ..."
#		chown -- "$user:$group" "$file" 2>/dev/null
#		chmod "$mod" "$file" 2>/dev/null
#	fi
#done <saved-permissions

#copy new .xinitrc
cp -a etc/skel/.xinitrc root/.xinitrc

cd "${thepwd}"

while true; do
printf "Type the alphanumeric hostname you wish to use for this machine and press return\n(\"-\" characters are also allowed).\n"
	read hostname
	#check if alphanumeric
	if [ "$(echo "$hostname" | sed "s#[A-Z]\|[a-z]\|[0-9]\|\-##g" )" = "" ]; then
		printf "%s\n" "$hostname" > "${dest}/etc/hostname"
		chmod 644 "${dest}/etc/hostname"
		chown root:root "${dest}/etc/hostname"

		printf "127.0.0.1\tlocalhost\n" > "${dest}/etc/hosts"
		printf "127.0.1.1\t%s\n" "$hostname" >> "${dest}/etc/hosts"
		printf "::1\t\tlocalhost ip6-localhost ip6-loopback\n" >> "${dest}/etc/hosts"
		printf "ff02::1\t\tip6-allnodes\n" >> "${dest}/etc/hosts"
		printf "ff02::2\t\tip6-allrouters\n" >> "${dest}/etc/hosts"
		chmod 644 "${dest}/etc/hosts"
		chown root:root "${dest}/etc/hosts"

		break
	fi
done

set_locale "${dest}"
set_timezone "${dest}"
choose_layout "${dest}"

howManyGLeft="$(df -h "$dest" | head -n 2 | tail -n 1 | tr -s " " | cut -d " " -f 4)"
if [ "$(printf "%s" "$howManyGLeft" | grep "G")" != "" ]; then
while true; do
		printf "Would you like to create a swap [Y/N]?"
		read option5
	if [ "${option5}" = "Y" ] || [ "${option5}" = "y" ]; then
		howManyGLeft="$(df -h "$dest" | head -n 2 | tail -n 1 | tr -s " " | cut -d " " -f 4)"
		printf "You have %s availiable for a swap.\n" "$howManyGLeft"
		printf "How big would you like your swap to be?\n"
			while true; do
				printf "... Type a number less than %s or type \"C\" to cancel\n" "$howManyGLeft"
				read option6
				#cope with the user typing a suffix of G
				if [ "$(printf "%s" "$howManyGLeft" | grep "G")" != "" ]; then
					option6="$(printf "%s" "$option6" | cut -d "G" -f1 )"
				fi
				if [ "${option6}" = "C" ] || [ "${option6}" = "c" ]; then
					break
				else
					justTheNumberLeft="$(printf "%s" "$howManyGLeft" | cut -d "G" -f 1)"
					if [ "$(printf "%s < %s\n" "${option6}" "${justTheNumberLeft}" | bc)" = 1 ]; then
						printf "OK, creating a swap of %sG.\n" ${option6}
						head -c "${option6}G" /dev/zero > ${dest}/swapfile
						chmod 600 "${dest}/swapfile"
						${thechroot} ${dest} /sbin/mkswap /swapfile
						#NOTE TO SELF: =========== make sure we check the fstab before completely over-writing it
						printf "/swapfile none swap sw 0 0\n" > "${dest}/etc/fstab"
						printf "The swap will be there at boot\n"
						break
					fi
				fi
			done
		break
	elif [ "${option5}" = "N" ] || [ "${option5}" = "n" ]; then
		printf "No swap created.\n"
		break
	fi
done
else
printf "You do not have enough space to create a swap, so not bothering to ask\n"
fi

umount tempmount

#(
#echo a # set partition boot flag
#echo 1 # set partition boot flag
#echo w #Write
#echo q #Quit
#) | ${thefdisk} ${1}

cd

rm -rf /tmp/installToHDD

echo
echo "*** Remove the installation medium and press return. ***"

read nothing

umask "${OLD_UMASK}"

shutdown -r now
