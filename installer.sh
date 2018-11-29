#!/bin/bash
set -e

. settings.sh

wget="wget --show-progress -qcN -P ${SRC_FOLDER} " # add some defaults to wget: progress bar, flags to download the file only if missing or the remote one is newer

mkdir -p "${SRC_FOLDER}/tmp" ${DEST_FOLDER}

# some functions
d_setup(){
	# download and check cygwin's setup.ini
	$wget "${MIRROR}/${ARCH}/setup.ini"
	$wget "${MIRROR}/${ARCH}/sha512.sum"
	echo -e "\e[96m"
	cd ${SRC_FOLDER}
	sha512sum -c sha512.sum --ignore-missing || (
	# recursive call if something is off 
	rm setup.ini sha512.sum
	cd ..
	d_setup
	)
	echo -en "\e[0m"
	cd .. 
}

d_cygpkg(){
	# searches the required package in the setup.ini and downloads it
	# maybe it could be a good idea to remove previous versions ?!
	grep -cqE "^@ ${1}$" ${SRC_FOLDER}/setup.ini || (echo "${1} not found"; exit 255)
	# gets the line with the infos for the latest version; line format: "install: <uri> <file size> <sha512sum hash>"
    line=$(grep -E "^@ ${1}$" -A 50 ${SRC_FOLDER}/setup.ini | grep "install: " | head -1)
    uri=$(echo "$line" | awk '{print $2}')
	pkg_file="${SRC_FOLDER}/${uri##*/}" # I'll need this later 
    check_sum=$(echo "$line" | awk '{print $4}')
    $wget "${MIRROR}/${uri}"
    echo -e "\e[96m"
    sha512sum -c <<<"$check_sum ${pkg_file}" || exit 255
    echo -en "\e[0m"
}

d_wslbridge(){
	# gets the latest version of wslbridge
	rel="32"
	[[ "$ARCH" =~ "64" ]] && rel="64"
	uri=$(wget "https://github.com/rprichard/wslbridge/releases/latest" -qO - | grep -E 'href.*cygwin'${rel} | awk '{print $2}' | awk -F\" '{print $2}')
	pkg_file="${SRC_FOLDER}/${uri##*/}" # I'll need this later
	$wget "https://github.com${uri}"
	echo -e "\n\e[96mwslbridge\e[0m"
	# unfortunately, there's no checksum 
}

cp_frompkg(){
	# copy what's needed from 
	src="$1"
	cd ${SRC_FOLDER}/tmp # "dirty trick" in order to get the right folder structure without using on string manipulations (awk, sed, ...) 
	cp="cp --parents -rvup" # copy, only if missing or newer, to destination replicating the folder structure starting from the current folder

	dst="${DEST_FOLDER}"
	if [[ "$1" =~ "#" ]]; then
		src=$(echo $1 | awk -F'#' '{print $1}')
		dst="${dst}/$(echo $1 | awk -F'#' '{print $2}')"
		mkdir -p "${dst%/*}"
		cp="cp -rvup" # in this case we "rewrite" the folder structure, so we must not create the same folder structure
	fi
	for i in ${src}; do
		$cp ${i} "${dst}" || (
			# copy failed, usually 'cause file is in use ... you are running inside mintty
			# these are windows files/exceutables, so we cant' overwrite or delete them as in linux, so e have to move them
			# then retry the copy operation
			[ -f ${i} ] && ( # it's a file, otherwise ... i don't know
				t_dst="${dst%/}"; [ -d ${t_dst} ] && t_dst="${t_dst}/${i##*/}"
				mv -v "${t_dst}" "${t_dst}.2del"
				$cp ${i} "${dst}"
			)
		)
	done
	cd ../..
}

d_setup # download/upodate cygwin's setup.ini to get information about latest versions of the packages

# package list to be downloaded
# the "key", pkgs[key], must be a package name as written in the setup.ini ( ^@ <key>$ ) 
# the value is a string with a "space separated" list of all folders or files that you want from the original package
declare -A pkgs

# DISCLAIMER: I know zero to nil about licenses and stuff, my script downloads the packages and takes only the minimum necessary of files
#        I don't know if I should also copy the license files in the destination folder or not, if this goes against some regulation or something
#        just let me know if, what and how should I change in order to make it OK.

pkgs[mintty]="usr/bin/mintty.exe#bin/ "
pkgs[mintty]+="usr/share/mintty/icon "
# I don't care about translations so I'll comment it out for now 
#pkgs[mintty]+="usr/share/mintty/lang "
pkgs[mintty]+="usr/share/mintty/themes "

pkgs[cygwin]="usr/bin/cygwin1.dll#bin/ " 
pkgs[cygwin]+="usr/bin/cygwin-console-helper.exe#bin/ "


# some "magic": I use a function to download this package/archive, as it is not part of the cygwin
# I "signal" this by setting the key to ":"+<the name of the function>
# second "magic" ... copy files to different path, separate the src and dest paths by a "#" 
pkgs[:d_wslbridge]="wslbridge*/wslbridge*#bin/"



## my miserable, failed attempt to also get the xserver from the cygwin distribution working
#
#pkgs[xorg-server]="usr/bin etc/defaults/etc/X11/system.XWinrc#etc/X11/system.XWinrc"
#
#xreqs="libXfont2_2 libXfixes3 libXdmcp6 libxcb1 libxcb-util1 libxcb-ewmh2 libxcb-image0 libxcb-icccm4 libxcb-composite0 libXau6 libX11_6 libtirpc3 libpixman1_0 libnettle6 "
## up until around here it was the XWin.exe complaining about missing DLLs, afterwards was getting only an "?" 
#xreqs+="libxcb-shm0 libgcc1 libgssapi_krb5_2 "
#xreqs+="libcom_err2 zlib0 libbz2_1 libfontenc1 libfreetype6 libpng16 libkrb5support0 libkrb5_3 libk5crypto3 libintl8 libiconv2"
#for pkg in $xreqs; do
#	pkgs[$pkg]="usr/bin"
#done
## I've got the process running, some black window with some logs ... but couldn't seem to attach to it
 

# clean up leftovers from the last run # 2> /dev/null
find ${DEST_FOLDER} -name '*.2del' -delete  || echo -n ''

for pkg in "${!pkgs[@]}"; do
    rm -rf ${SRC_FOLDER}/tmp/*
    if [[ "$pkg" =~ ":" ]]; then # not cygwin package
    	${pkg##*:}  # call function
    else
		d_cygpkg $pkg # downloads the latest cygwin package, and sets the path to the file to pkg_file
	fi
    tar xf "$pkg_file" -C ${SRC_FOLDER}/tmp
	srcp=${pkgs[$pkg]} # path with the file/folder of interest
    [ "$srcp" != "" ] && for sp in ${srcp}; do cp_frompkg "${sp}"; done
done
rm -rf ${SRC_FOLDER}/tmp/*

# create a home folder for the current user in the destination folder
u=$(cmd.exe /C "echo %USERNAME%" | tr -d '\r')
mkdir -p ${DEST_FOLDER}/home/${u}
