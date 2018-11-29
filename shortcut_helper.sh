#!/bin/bash
set -e
[ $(which getopt) ] || (echo "Can't find getopt"; exit 255)
show_help(){
	cat<<-EOF
Usage:
 $0 <options>

Creates shortcuts for mintty in the current folder for each WSL distro it finds installed.

Options:
 -d, --desktop             also place a shortcut on the desktop of the current user.
 -s, --startmenu           also place a shortcut on the Start Menu of the current user.
 -L, --no-local            don't place a shortcut in the current folder.
 -p, --path                place a shortcut in the folder specified; should be a wsl path.

 -h, --help                display this help

EOF
	
}

PARSED=$(getopt -o "hdsLp:" -l "help,desktop,startmenu,no-local,path:" -n "$0" -- "$@")
eval set -- "$PARSED"
desktop_sh=0 start_sh=0 local_sh=1 path_sh=""


while true; do
    case "$1" in
        -h|--help)
        	show_help
            exit 0
            ;;
        -d|--desktop)
            desktop_sh=1
            shift
            ;;
        -s|--startmenu)
            start_sh=1
            shift
            ;;
        -L|--no-local)
            local_sh=0
            shift
            ;;
        -p|--path)
        	shift
        	path_sh="$1"
            shift
            ;;
        --)
            shift
            break
            ;;
        *)
            echo "Invalid arguments"
            exit 3
            ;;
    esac
done

[ $(( $desktop_sh + $start_sh + $local_sh )) -eq 0 ] && [ "$path_sh" == ""  ] && (echo "Current args would create no shortcut."; show_help; exit 3)

#echo "desktop_sh=${desktop_sh} start_sh=${start_sh} local_sh=${local_sh} path_sh=${path_sh}"
#exit
. settings.sh


build_shortcut(){
	lnk="${1}\\${distro}.lnk"
	w_minty_path=$(wslpath -aw $(find $DEST_FOLDER -name mintty.exe))
	sh_cmd="\$ws = New-Object -ComObject WScript.Shell; "
	sh_cmd+="\$s = \$ws.CreateShortcut(\"${lnk}\"); "
	sh_cmd+="\$s.TargetPath = \"${w_minty_path}\"; "
	sh_cmd+="\$s.Arguments = \"--WSL='${distro}' ${mintty_args}\"; "
	sh_cmd+="\$s.Description = \"${distro} - mintty\"; "
	sh_cmd+="\$s.WorkingDirectory = \"$(wslpath -aw mintty)\"; "
	sh_cmd+="\$s.IconLocation = \"$(wslpath -aw $(grep -lr WslLaunch ${d_u_path}/*.exe))\"; "
	sh_cmd+="\$s.Save()"
	powershell.exe "$sh_cmd"
}

get_sys_folder(){
	cmd="Get-ItemProperty -Path \"Registry::HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders\" -name \"${1}\" | "
	cmd+="Format-List \"${1}\" " 
	powershell.exe "${cmd}" | tr -d '\r' | grep -E "^${1}" | head -1 | awk -F' : ' '{print $2}'
}

while read -r line; do
	distro=$(awk '{print $1}' <<< "$line")
	d_w_path=$(awk '{print $2}' <<< "$line")
	d_u_path=$(wslpath -au "${d_w_path}")
	echo -e "\e[96m${distro}\e[0m"
	[ "${local_sh}" == "1" ] && (echo -e "\tCreating shortcut in the installation folder"; build_shortcut $(wslpath -aw "${DEST_FOLDER}") )
	[ "${desktop_sh}" == "1" ] && ( echo -e "\tCreating shortcut on the Desktop";  build_shortcut "$(get_sys_folder "Desktop")" )
	[ "${start_sh}" == "1" ] && ( echo -e "\tCreating shortcut in the StartMenu";  build_shortcut "$(get_sys_folder "Start Menu")" )
	[ "${path_sh}" != "" ] && ( echo -e "\tCreating shortcut in $(wslpath -aw "${path_sh}")";  build_shortcut "$(wslpath -aw "${path_sh}")" )
done<<<$(powershell.exe '(Get-ChildItem HKCU:\Software\Microsoft\Windows\CurrentVersion\Lxss | ForEach-Object {Get-ItemProperty $_.PSPath}) | select State,DistributionName,BasePath'  | tr -d '\r' | \grep -E '^\s+1' | awk '{print $2,$3}')

