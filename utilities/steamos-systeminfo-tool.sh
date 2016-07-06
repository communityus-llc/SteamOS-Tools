#!/bin/bash
#-------------------------------------------------------------------------------
# Author:	Michael DeGuzis
# Git:		https://github.com/ProfessorKaos64/SteamOS-Tools
# Scipt name:	steamos-info-tool.sh
# Script Ver:	0.1.7
# Description:	Tool to collect some information for troubleshooting
#		release
#
# See:		
#
# Usage:	./steamos-info-tool.sh
# Opts:		[--testing]
#		Modifys build script to denote this is a test package build.
# -------------------------------------------------------------------------------

function_install_utilities()
{
	
	echo -e "==> Installing needed software...\n"

	PKGS="p7zip-full"

	for PKG in ${PKGS};
	do

		# This one-liner returns 1 (installed) or 0 (not installed) for the package
		if ! $(dpkg-query -W --showformat='${Status}\n' ${PKG} | grep "ok installed"); then
	
			sudo apt-get install -y ${PKG}
		else
	
			echo -e "Package: ${PKG} [OK]\n"
	
		fi

	done

}

function_set_vars()
{
  
	TOP=${PWD}

	DATE_LONG=$(date +"%a, %d %b %Y %H:%M:%S %z")
	DATE_SHORT=$(date +%Y%m%d)

	LOG_ROOT="${HOME}/logs"
	LOG_FOLDER="${LOG_ROOT}/steamos-logs"
	LOG_FILE="${LOG_FOLDER}/steam_info.txt"

	# Remove old logs to old folder and clean folder

	cp -r ${LOG_FOLDER} ${LOG_FOLDER}.old &> /dev/null
	rm -rf ${LOG_FOLDER}/*
	
	# Remove old zip files to avoid clutter.
	# Max: 90 days
	find ${LOG_ROOT} -mtime +90 -type f -name "steamos-logs*.zip" -exec rm {} \;

	# Create log folder if it does not exist
	if [[ ! -d "${LOG_FOLDER}" ]]; then

		mkdir -p "${LOG_FOLDER}"

	fi

	STEAM_CLIENT_VER=$(grep "version" /home/steam/.steam/steam/package/steam_client_ubuntu12.manifest \
	| awk '{print $2}' | sed 's/"//g')
	STEAM_CLIENT_BUILT=$(date -d @${STEAM_CLIENT_VER})

}

function_gather_info()
{

	# OS
	echo -e "==================================="
	echo -e "OS Information"
	echo -e "===================================\n"

	lsb_release -a
	
	# Software
	echo -e "\n==================================="
	echo -e "Software Information"
	echo -e "===================================\n"

	dpkg-query -W -f='${Package}\t${Architecture}\t${Status}\t${Version}\n' "valve-*" "*steam*" "nvidia*" "fglrx*" "*mesa*"
	
	echo -e "\n==================================="
	echo -e "Steam Information"
	echo -e "===================================\n"
	
	echo "Steam client version: ${STEAM_CLIENT_VER}" 
	echo "Steam client built: ${STEAM_CLIENT_BUILT}"

}

function_gather_logs()
{
	
	echo -e "\n==> Gathering logs (sudo required for system paths)\n"
  
	# Simply copy logs to temp log folder to be tarballed later
	pathlist=()
	pathlist+=("/tmp/dumps/steam_stdout.txt")
	pathlist+=("/home/steam/.steam/steam/package/steam_client_ubuntu12.manifest")
	pathlist+=("/var/log/unattended-upgrades/unattended-upgrades-dpkg.log")
	pathlist+=("/var/log/unattended-upgrades/unattended-upgrades-shutdown.log")
	pathlist+=("/var/log/unattended-upgrades/unattended-upgrades.log")
	pathlist+=("/var/log/unattended-upgrades/unattended-upgrades-shutdown-output.log")
	pathlist+=("/run/unattended-upgrades/ready.json")
	
	for file in "${pathlist[@]}"
	do
		# Suprress only when error/not found
		sudo cp -v ${file} ${LOG_FOLDER} 2>/dev/null
	done
	
	# Notable logs not included right now
	# /home/steam/.steam/steam/logs*
  
}

main()
{
	
	echo -e "=============================================="
	echo -e "SteamOS Info Tool"
	echo -e "==============================================\n"

	# Install software
	function_install_utilities

	# get info about system
	function_gather_info

	# Get logs
	function_gather_logs

	# Archive log filer with date
	echo -e "\n==> Archiving logs\n"
	7za a "${LOG_FOLDER}_${DATE_SHORT}.zip" ${LOG_FOLDER}/*
  
}

# Main
clear
function_set_vars
main | tee ${LOG_FILE}