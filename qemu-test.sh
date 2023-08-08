#!/bin/sh
if [ "$1" = "nocd" ]; then
qemu-system-ppc -M mac99 -m 1.5G -hda thehdd.qcow -boot d
else
qemu-system-ppc -m 1.5G -M mac99 -hda thehdd.qcow -cdrom linosx-powerpc.iso -boot d
fi
