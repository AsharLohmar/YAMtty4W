#!/bin/bash
set -e
[ -n "$(command -v getopt)" ] || (echo "Can't find getopt"; exit 255)
show_help(){
	cat<<-EOF
Usage:
 $0 <options> [distribution]

Creates shortcuts for mintty in the current folder for each WSL distro it finds installed or if a "distribusion" string is passed, only for those that match the string

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

sd=""
if [ "${1% }" != "" ]; then
	if [ "$(wslconfig.exe /l | tr -d '\r\0' | grep -c "${1}")" == 0  ]; then
		echo "Unrecognized distribution";
		echo -n "Available ";wslconfig.exe /l
		exit 255
	else
		sd="${1}"
	fi
fi

[ $(( desktop_sh + start_sh + local_sh )) -eq 0 ] && [ "$path_sh" == ""  ] && (echo "Current args would create no shortcut."; show_help; exit 3)

#echo "desktop_sh=${desktop_sh} start_sh=${start_sh} local_sh=${local_sh} path_sh=${path_sh}"
#exit
. settings.sh


build_shortcut(){
	lnk="${1}\\${distro}.lnk"
	w_minty_path=$(wslpath -aw "$(find "$DEST_FOLDER" -name mintty.exe)")
	sh_cmd="\$ws = New-Object -ComObject WScript.Shell; "
	sh_cmd+="\$s = \$ws.CreateShortcut(\"${lnk}\"); "
	sh_cmd+="\$s.TargetPath = \"${w_minty_path}\"; "
	sh_cmd+="\$s.Arguments = \"--WSL='${distro}' ${mintty_args}\"; "
	sh_cmd+="\$s.Description = \"${distro} - mintty\"; "
	sh_cmd+="\$s.WorkingDirectory = \"$(wslpath -aw "$DEST_FOLDER")\"; "
	if [ "$(grep -lr WslLaunch "${d_u_path}"/*.exe 2>/dev/null | wc -l)" == 0 ]; then
		sh_cmd+="\$s.IconLocation = \"${w_minty_path}\"; "
	else
		sh_cmd+="\$s.IconLocation = \"$(wslpath -aw "$(grep -lr WslLaunch "${d_u_path}"/*.exe)")\"; "
	fi
	sh_cmd+="\$s.Save()"
	"$ps_cmd" "$sh_cmd"
}

get_sys_folder(){
	cmd="Get-ItemProperty -Path \"Registry::HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders\" -name \"${1}\" | "
	cmd+="Format-List \"${1}\" " 
	"$ps_cmd" "${cmd}" | tr -d '\r' | grep -E "^${1}" | head -1 | awk -F' : ' '{print $2}'
}

if [ -n "$(command -v powershell)" ]; then
	ps_cmd="powershell"
else
	ps_cmd="$(wslpath -a "$(cmd.exe /c "where powershell" | tr -d '\r')")"
fi
while read -r l; do
	distro="$(awk -F'###' '{print $1}' <<< "$l")"
	d_w_path="$(awk -F'###' '{print $2}' <<< "$l")"
	d_u_path="$(wslpath -au "${d_w_path}")"
	echo -e "\e[96m${distro}\e[0m"
	[ "${local_sh}" == "1" ] && (echo -e "\tCreating shortcut in the installation folder"; build_shortcut "$(wslpath -aw "${DEST_FOLDER}")" )
	[ "${desktop_sh}" == "1" ] && ( echo -e "\tCreating shortcut on the Desktop";  build_shortcut "$(get_sys_folder "Desktop")" )
	[ "${start_sh}" == "1" ] && ( echo -e "\tCreating shortcut in the StartMenu";  build_shortcut "$(get_sys_folder "Start Menu")" )
	[ "${path_sh}" != "" ] && ( echo -e "\tCreating shortcut in $(wslpath -aw "${path_sh}")";  build_shortcut "$(wslpath -aw "${path_sh}")" )
done<<<"$("$ps_cmd" "(Get-ChildItem HKCU:\Software\Microsoft\Windows\CurrentVersion\Lxss | ForEach-Object {Get-ItemProperty \$_.PSPath}) | select State,DistributionName,BasePath"  | tr -d '\r' | \grep -E '^\s+1' | awk '{print $2"###"$3}' | grep "${sd}")"

