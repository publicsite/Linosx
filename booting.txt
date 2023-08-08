==Notes==

The software is provided without warranty and will wipe your Mac.

It is a custom version of debian unstable from debian ports, using Xfce that should work on PowerMacs (but only tested so far in a vm).

The ISO requires a DVD drive or USB drive.

The ISO will only work on Powermacs with ONE IDE type hard drive installed. It is unknown whether a SATA hard drive will work in IDE mode.

The ISO will only work with ONE DVD drive installed if booting from DVD.

Remember, Linux is case-sensitive, meaning you have to use the right capital letters.

==Booting from DVD==

Burn the ISO image to DVD and boot with the DVD in the DVD drive?

==USB Booting==

dd the image to USB if you haven't already received a USB.

Make sure you have the USB device connected before turning on the computer.

It is likely you will have to boot through openfirmware, however, if you've installed a system onto a USB device then you can try restarting the machine whilst holding the Option key. You may be able to choose your USB device to boot from (this would work on a G3 iBook I had, but not a G4 iBook). You can also try holding down simultaneously Command-Option-Shift-Delete during start-up. This will bypass the internal hard drive and boot from an external drive or CD. If you want to force a particular SCSI device use cmd-opt-shift-delete-# where # = SCSI ID number.

If those don't work, restart the machine into openfirmware (hold down Command-Option-o-f after turning on, and keep pressed until you see the openfirmware prompt). Although it is not always necessary, you are recommended to first run the command:

probe-usb

To boot the USB device you can usually use one of the following commands (on the author's ibook usb0 is the port closest to the front, usb1 is towards the back):

boot usb0/disk@1:2,\\tbxi
boot usb1/disk@1:2,\\tbxi 

You can abbreviate the commands to (they should do exactly the same thing - openfirmware will do its best to fill in the blanks):

boot usb0/disk:2,\\tbxi
boot usb1/disk:2,\\tbxi
boot usb0/@1:2,\\tbxi
boot usb1/@1:2,\\tbxi

Please add to this list if you use something different:

boot usb-2a/disk@1:2,\\tbxi
boot ud:2,\\tbxi

To list the files on the disk use the dir command. For example:

dir usb0/disk@1:2,\

If you look at the contents of the iso you may be wondering where yaboot lives and how that relates to the commands above. The bootloader files and directories are given special attributes/types and this allows the shortened \\yaboot to be used (it effectively tells openfirmware to search for yaboot in a blessed folder). If you wanted to use the whole path it would be something like this:

boot usb0/disk@1:2,\install\tbxi

You have to use this expanded path if you've copied the files in a way that does not preserve the special attributes.

==After boot==

Type "root" as the username and "root" as the password at the login screen.

Press:
			"2"
and hit return to format the disk

Press:
			"3"
and hit return to go to the next screen.

It will then say "Copying the files", wait a long time until the next part;

When it says "Type the alphanumeric hostname you wish to use for this machine [...]",
Type:
			"Linosx"
and hit return.

When it says: "Type L to see locales [...]",
Type:
			"en_GB.UTF-8"
and hit return.

When it says: "Type L to see regions [...]",
Type:
			"Europe"
and hit return.
When it says "Type L to see keyboard layouts [...]"
Type:
			"gb"
and hit return.
It will then say , "Please wait while I print your variants [...]", wait a long time until the next part;
After it prints the variants,
Type:
			"mac"
When it says "Would you like to create a swap [...]",
Type:
			"y"
When it says "How big would you like your swap to be? [...]",
Type:
			"1G"
Then remove the installation disk from the drive and press return.