#!/usr/local/bin/bash

#################################################
# Functions to check patches			#
#################################################

source config.sh
source utils.sh


#################################################
# Download the attachment id passed in		#
# $1: the patch id				#
# Return the name of the patch in the		#
# local filesystem				#
#################################################
download_attachment()
{
	local file_name
	local patch_id
	patch_id="${1}"
	file_name=$(${BUGZ_CMD} attachment "${patch_id}" | grep Saving \
		| cut -f3 -d: | tr -d \" | tr -d "[:blank:]")

	echo "${file_name}"
}
	

#################################################
# Apply a patch to a port			#
# $1: the pr the patch is coming from 		#
# $2: the name of the patch file		#
# Return: 0 if patch is apply succesfully, 1	#
# otherwise					#
#################################################
apply_patch()
{
	local patch_file
	local port_name
	local pr
	local pr_dir
	local strip_n
	
	pr="${1}"
	patch_file="${2}"
	pr_dir="${WRKDIR}"/"${pr}"
	port_name="$(get_port_name)"

	strip_n=$(get_strip_level "${patch_file}")
	
	# Move patch to working dir
	mv "${patch_file}" "${pr_dir}"

	cd  "${pr_dir}"/"${port_name}" || return 1

	patch -p"${strip_n}" -E < ../../"${patch_file}" &> /dev/null

	if [[ ${?} -ne 0 ]]; then
		echo 1
		return
	fi

	# After applying the patch, we should delete the .orig
	# so portlint does not get mad
	find "${pr_dir}" -name '*.orig' -delete

	echo 0
	return
}

#################################################
# Try to apply a patch from a pr		#
# $1: pr id					#
# $2: patch id					#
#################################################
try_patch()
{
	local patch_file
	local patchid
	local port_dir
	local pr
	local success

	pr="${1}"
	patchid="${2}"
	
	port_dir=$(checkout_port "${pr}")
	patch_file=$(download_attachment "${patchid}")
	success=$(apply_patch "${pr}" "${patch_file}")

	if [[ "${success}" -ne 0 ]]; then
		echo "Patch does not apply"
		exit
	fi

	# OK, so we could apply the patch. Let's run some checks
	# on the port

	portlint -AC "${port_dir}"
	portclippy  "${port_dir}"/Makefile
}
