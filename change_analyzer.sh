#!/usr/local/bin/bash

source config.sh
source utils.sh

#################################################
# Functions to help analyze the changes made to	#
# a port					#
#################################################


#################################################
# Check that entries in distinfo match those	#
# from DISTFILES.				#
# This includes cases where DISTVERSION is	#
# bumped but distinfo is not updated		#
#################################################
check_distfiles()
{
	for fich in $(make -VDISTFILES | cut -f1 -d:);do
		r=$(grep -c -E "SIZE.*${fich}" distinfo)
		if [[ ${r} -ne 1 ]]; then
			echo ${fich} not in distinfo
		fi
	done
}

#################################################
# Check that PORTREVISION is removed if there	#
# was a change to DISTVERSION or PORTVERSION	#
#################################################
check_portrevision()
{
	local diff
	local res
	local has_portrevision

	diff=$(svn diff Makefile)
	res=$(echo "${diff}" | grep -E '^+' | grep -E 'PORTVERSION|DISTVERSION')
	has_portrevision=$(grep PORTREVISION Makefile)

	if [[ -n "${res}" && -n "${has_portrevision}" ]]; then
		# There were changes to PORT/DIST VERSION
		# so PORTREVISION is not needed
		echo PORTREVISION should be removed
	fi
	
}


#################################################
# Driver function. It calls all the other	#
# analyzers.					#
# $1: Port directory to analyze			#
#################################################
analyze_changes()
{
	local port_dir
	port_dir="${1}"
	echo Analyzing changes in "${port_dir}"
	# Change to that directory so we work as if we
	# are being executed in that directory
	cd "${port_dir}"

	# See if distinfo is OK
	check_distfiles

	# Check if there is a PORTREVISION left
	check_portrevision

	# Return to previous directory
	cd -
}

