# change to a mirror close to you from the list available at https://cygwin.com/mirrors.html
MIRROR="http://bo.mirror.garr.it/mirrors/sourceware.org/cygwin"

ARCH=$(uname -p) # do we need it or we are safe with a constant "x86_64" ? does anyone still use 32 bit OS anymore ?

DEST_FOLDER="/mnt/d/tools/YAMtty4W"
SRC_FOLDER="pkg"
