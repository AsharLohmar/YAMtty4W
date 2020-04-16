# YAMtty4W - Yet another Mintty 4 WSL

Yeah, so, as the name says here's to you "Yet another Mintty 4 WSL".

### Why's that ? 
Mainly ...  'cause I could and I was bored. 

### So what is it?  
A bunch of bash scripts that will download and extract the minimum of cygwin packages required to run mintty while trying to give as much control as possible on where to "install" (just a fancy word for copying the stuff) and where to create shortcuts.

#### settings.sh
Holds a few configuration parameters:
``` shell
# a cygwin mirror site change to a mirror close to you 
# from the list available at https://cygwin.com/mirrors.html
MIRROR="http://bo.mirror.garr.it/mirrors/sourceware.org/cygwin"

ARCH=$(uname -p) # do we need it or we are safe with a constant "x86_64" ?
                 # does anyone still use 32 bit OS anymore ?

# the installation/destination folder
DEST_FOLDER="/mnt/d/tools/YAMtty4W"

# folder where to keep the downloaded packages
SRC_FOLDER="pkg"
```

#### setup.sh
Downloads the Cygwin packages and copies the necessary files to the destination folder, no arguments needed just "launch and pray"
``` shell
# make sure it's executable and
./setup.sh
```

#### shortcut_helper.sh
Helps creating shortcuts for mintty in various locations for all the WSL distributions it can find installed. The mintty will be launched with `--WSL='${distro}' <$mintty_args>`, which is defined in the settings.sh the default value is `-~ /bin/bash -l`.

``` shell
$ ./shortcut_helper.sh -h
Usage:
 ./shortcut_helper.sh <options>

Creates shortcuts for mintty in the current folder for each WSL distro it finds installed.

Options:
 -d, --desktop             also place a shortcut on the desktop of the current user.
 -s, --startmenu           also place a shortcut on the Start Menu of the current user.
 -L, --no-local            don't place a shortcut in the current folder.
 -p, --path                place a shortcut in the folder specified; should be a WSL path.

 -h, --help                display this help
```

## GTD (Getting things done)
Everything happens inside your WSL, as dependencies everything should already be there on standard installation (maybe wget is missing), make sure powershell.exe is in your `$PATH`. 
Developed and tested on a Ubuntu 18.04. 

1. Get a copy of the scripts, either with a `git clone` or by downloading as a zip.
2. modify/configure settings.sh 
3. run the setup.sh script
4. run the shortcut_helper.sh script with the parameters you need/want.
5. ...
6. (you thought I was gonna say "Profit") whenever you want to update/check for updates of the packages just run the setup.sh again, it will download files only if missing or newer.

# Credits/Disclaimer

As my work was only to write these script, the credits should go to the appropriate owners and developers of the software the scripts are downloading:
 * [mintty](http://mintty.github.io/) - Mintty is the Cygwin Terminal emulator, also available for MSYS and Msys2.
 * [Cygwin](https://www.cygwin.com) - a DLL (cygwin1.dll) which provides substantial POSIX API functionality.
 * ~[wslbridge](https://github.com/rprichard/wslbridge)~ [wslbridge2](https://github.com/Biswa96/wslbridge2) - Bridge from Cygwin to WSL pty/pipe I/O

