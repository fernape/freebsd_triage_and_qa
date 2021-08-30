#!/usr/local/bin/bash

#################################################
# Functions to check patches			#
#################################################

source $(dirname ${BASH_SOURCE[0]})/config.sh
source $(dirname ${BASH_SOURCE[0]})/utils.sh

#################################################
# Counts the number of non-obsolete patches	#
# this PR has					#
# $1: the patch id				#
# Return: The number of patches			#
#################################################
number_of_patches()
{
	local attach_size
	local bug_id
	bug_id="${1}"

	attach_size=$(${CURL_CMD}/"${bug_id}"/attachment \
		| ${JQ} ".bugs.\"${bug_id}\"[] | select(.is_obsolete == 0) | .id" \
		| wc -l)

	echo "${attach_size}"
}

#################################################
# Download patch from PR. Assumes there is	#
# exactly one non-obsolete patch to download	#
# $1: the PR number				#
# Return the name of the patch in the		#
# local filesystem				#
#################################################
download_patch()
{
	local file_name
	local pr
	pr="${1}"
	file_name="/tmp/${pr}".patch

	${CURL_CMD}/"${pr}"/attachment \
			| ${JQ} ".bugs.\"${pr}\"[] | select(.is_obsolete == 0) |
			select (.is_patch == 1) | .data" \
			| sed -e 's/"//g' \
			| b64decode -r > "${file_name}"

	echo "${file_name}"
}
	

#################################################
# Apply a patch to a port			#
# $1: the name of the patch file		#
# Return: 0 if patch is apply succesfully, 1	#
# otherwise					#
#################################################
apply_patch()
{
	local patch_file
	local port_name
	local strip_n
	
	patch_file="${1}"
	port_name="$(get_port_name)"

	strip_n=$(get_strip_level "${patch_file}")
	
	cd  "${port_name}" || return 1

	patch -p"${strip_n}" -E -i "${patch_file}" &> /dev/null

	if [[ ${?} -ne 0 ]]; then
		echo 1
		return
	fi

	# After applying the patch, we should delete the .orig
	# so portlint does not get mad
	find "${WRKDIR}/${port_name}" -name '*.orig' -delete

	echo 0
}


#################################################
# Run some linters in the port directory	#
# $1: directory of the port to check. Can be	#
# empty and it assumes the local directory	#
#################################################
run_linters()
{
	local port_dir
	local result

	port_dir="${1}"

	portlint -AC "${port_dir}" | tee portlint.out
	portclippy  "${port_dir}"/Makefile | tee portclippy.out
	portfmt  -D "${port_dir}"/Makefile | tee portfmt.out

	if [[ -s portlint.out ]]; then
		result=$(grep -E 'FATAL|WARN' portlint.out \
			| grep -v -E 'happy|journal' \
			| cut -f2-20 -d:
		)

		if [[ -n "${result}" ]]; then
			push_to_report "Q/A: ${result}"
			push_to_report "LINTERS"
		fi
	fi

	# Run igor on pkg-descr for typos
	igor_res="$(igor ${port_dir}/pkg-descr)"
	if [[ -n "${gor_res}" ]]; then
		push_to_report "Q/A: ${igor_res}"
	fi


	# Clean up
	rm {portlint,portclippy,portfmt}.out
}

#################################################
# Try to apply a patch from a pr		#
# This function assumes there is only one patch	#
# $1: pr id					#
#################################################
try_patch()
{
	local patch_file
	local patchid
	local port_dir
	local pr
	local ret
	local success

	pr="${1}"
	
	port_dir=$(create_pr_branch "${pr}")
	patch_file=$(download_patch "${pr}")
	success=$(apply_patch "${patch_file}")

	if [[ "${success}" -ne 0 ]]; then
		echo "Patch does not apply"
		push_to_report "PATCH_FAILED"
		ret="$(file "${WRKDIR}/${pr}/${patch_file}" | grep 'CRLF')"
		if [[ -n "${ret}" ]]; then
			push_to_report "PATCH_HAS_CRLF"
		fi
		return
	fi

	# OK, so we could apply the patch. Let's run some checks
	# on the port

	run_linters "${port_dir}"
}
