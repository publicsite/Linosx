#!/bin/sh

OLD_UMASK="$(umask)"
umask 0022

#myBuild options

#environment variables
export myBuildHome="$1"
export myBuildHelpersDir="${myBuildHome}/helpers"
export myBuildSourceDest="${myBuildHome}/sourcedest"
export myBuildExtractDest="${myBuildHome}/extractdest"
export myBuildsDir="${myBuildHome}/myBuildsBuild"

mkdir "$myBuildSourceDest"
mkdir "$myBuildExtractDest"

export J="-j12"

#this would be for binutils search paths, but i am playing my luck to see if i can go without it
#ld --verbose | grep SEARCH_DIR | tr -s ' ;' \\012
export BITS='32'

#architecture='x86' #the architecture of the target (used for building a kernel)
#export architecture

export TARGET="powerpc-linux-gnu" #the toolchain we're creating
export HOST="$TARGET"
export BUILD="$(gcc -v 2>&1 | grep "^Target: " | cut -c 9-)" #the toolchain we're compiling from, can be found by reading the "Target: *" field from "gcc -v", or "gcc -v 2>&1 | grep Target: | sed 's/.*: //" for systems with grep and sed

export SYSROOT="${myBuildHome}/rootfs" #the root dir

mkdir "$SYSROOT"

export TEMP_SYSROOT="/"

export PREFIX='/usr' #the location to install to

###	install the programs	###

export DISPLAY=:0.0
export LIBGL_ALWAYS_SOFTWARE=1

cd /usr/lib/powerpc-linux-gnu
ln -s libext2fs.so.2 libext2fs.so

cd "${myBuildHome}/rootfs/usr/lib/powerpc-linux-gnu"
ln -s libext2fs.so.2 libext2fs.so
cd "${myBuildHome}"

#"${myBuildsDir}/yaboot/yaboot.myBuild" extract
#"${myBuildsDir}/yaboot/yaboot.myBuild" build
#"${myBuildsDir}/yaboot/yaboot.myBuild" install

#use powerpc
#use pmac32_defconfig

"${myBuildsDir}/linux/linux.myBuild" extract
"${myBuildsDir}/linux/linux.myBuild" build headers
"${myBuildsDir}/linux/linux.myBuild" install headers

"${myBuildsDir}/linux/linux.myBuild" extract
"${myBuildsDir}/linux/linux.myBuild" build kernel
"${myBuildsDir}/linux/linux.myBuild" install kernel

umask "${OLD_UMASK}"
