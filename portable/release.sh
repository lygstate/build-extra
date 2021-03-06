#!/bin/sh

# Build the portable Git for Windows.

test -z "$1" && {
	echo "Usage: $0 <version> [optional components]"
	exit 1
}

die () {
	echo "$*" >&1
	exit 1
}

ARCH="$(uname -m)"
PROGRAMFILESENV=PROGRAMFILES
case "$ARCH" in
i686)
	BITNESS=32
	;;
x86_64)
	BITNESS=64
	PROGRAMFILESENV=ProgramW6432
	;;
*)
	die "Unhandled architecture: $ARCH"
	;;
esac
VERSION=$1
shift
TARGET="$HOME"/PortableGit-"$VERSION"-"$BITNESS"-bit.7z.exe
OPTS7="-m0=lzma -mx=9 -md=64M"
TMPPACK=/tmp.7z
SHARE="$(cd "$(dirname "$0")" && pwd)"

case "$SHARE" in
*" "*)
	die "This script cannot handle spaces in $SHARE"
	;;
esac


# Generate a couple of files dynamically

mkdir -p "$SHARE/root/tmp" ||
die "Could not make tmp/ directory"

# Make a list of files to include
LIST="$(ARCH=$ARCH BITNESS=$BITNESS sh "$SHARE"/../make-file-list.sh "$@")" ||
die "Could not generate file list"

# 7-Zip will strip absolute paths completely... therefore, we can add another
# root directory like this:

LIST="$LIST $SHARE/root/*"


# Make the self-extracting package

type 7za ||
pacman -S p7zip ||
die "Could not install 7-Zip"

echo "Creating archive" &&
(cd / && 7za a $OPTS7 $TMPPACK $LIST) &&
(cat "$SHARE/../net-installer/7zSD.sfx" &&
 echo ';!@Install@!UTF-8!' &&
 echo 'Progress="yes"' &&
 echo 'Title="Portable Git for Windows"' &&
 echo 'BeginPrompt="This program installs a complete Git for Windows"' &&
 echo 'CancelPrompt="Do you want to cancel Git installation?"' &&
 echo 'ExtractDialogText="Please, wait..."' &&
 echo 'ExtractPathText="Where do you want to install Git for Windows?"' &&
 echo 'ExtractTitle="Extracting..."' &&
 echo 'GUIFlags="8+32+64+256+4096"' &&
 echo 'GUIMode="1"' &&
 echo 'InstallPath="%'$PROGRAMFILESENV'%\\Git"' &&
 echo 'OverwriteMode="0"' &&
 echo ';!@InstallEnd@!7z' &&
 cat "$TMPPACK") > "$TARGET" &&
echo "Success! You will find the new installer at \"$TARGET\"." &&
echo "It is a self-extracting .7z archive (just append .exe to the filename)" &&
rm $TMPPACK

