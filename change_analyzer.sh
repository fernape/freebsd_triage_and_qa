#!/usr/local/bin/bash

source config.sh
source templates.sh
source utils.sh

MAKEFILEDIFF=""

#################################################
# Functions to help analyze the changes made to	#
# a port					#
#################################################


#################################################
# Helper function that checks if the port has	#
# a certain variable				#
# $1: variable to look for			#
# $2: Makefile where to be searched		#
# Returns 1 if the varible is used, 0 otherwise #
#################################################
variable_in_makefile()
{
	local makefile
	local res
	local variable

	variable="${1}"
	makefile="${2}"

	res=$(grep -E "^"${variable}"" "${makefile}")

	if [[ -n "${res}" ]]; then
		echo 1
		return
	fi

	echo 0
}

#################################################
# Check if a variable has been changed		#
# S1: variable to be checked			#
# $2: diff to do the check			#
# Returns 1 if changed, 0 otherwise		#
#################################################
variable_changed()
{
	local diff
	local res
	local variable

	variable="${1}"
	diff="${2}"

	res=$(echo "${diff}" | grep -E '^+' | grep -E "${variable}")

	if [[ -n "${res}" ]]; then
		echo 1
		return
	fi

	echo 0
}

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
# $1: Makefile diff				#
#################################################
check_portrevision()
{
	local diff
	local res
	local has_portrevision

	diff="${1}"
	if [[ $(variable_changed PORTVERSION "${diff}") -eq 1 ||
		$(variable_changed DISTVERSION "${diff}") -eq 1 ]]; then
			res=1
	fi

	has_portrevision=$(grep PORTREVISION Makefile)

	if [[ -n "${res}" && -n "${has_portrevision}" ]]; then
		# There were changes to PORT/DIST VERSION
		# so PORTREVISION is not needed
		push_to_report "REMOVE_PORTREVISION"
	fi
	
}


#################################################
# Check that if the port uses GH_TAGNAME or	#
# GH_TUPLE they arechanged if			#
# PORTVERSION/DISTVERSION is changed too.	#
# $1: diff to be analyzed			#
#################################################
check_gh_commit()
{
	local diff

	diff="${1}"

	if [[ $(variable_in_makefile GH_TAGNAME Makefile) -eq 1 ]]; then
		if [[ $(variable_changed GH_TAGNAME "${diff}") -ne 1 ]]; then
			push_to_report "GH_TAGTUPLE"
			return
		fi
	fi

	if [[ $(variable_in_makefile GH_TUPLE Makefile) -eq 1 ]]; then
		if [[ $(variable_changed GH_TUPLE "${diff}") -ne 1 ]]; then
			push_to_report "GH_TAGTUPLE"
		fi
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

	# Store the whole diff so we don't have to
	# calculate it again and again

	MAKEFILEDIFF=$(svn diff Makefile)

	# See if distinfo is OK
	check_distfiles

	# Check if there is a PORTREVISION left
	check_portrevision "${MAKEFILEDIFF}"

	# Check if the port should change GH_* to be properly updated
	check_gh_commit "${MAKEFILEDIFF}"

	# Return to previous directory
	cd -
}

