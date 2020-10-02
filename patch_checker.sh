#!/usr/local/bin/bash

#################################################
# Functions to check patches			#
#################################################

source config.sh
source utils.sh

#################################################
# Counts the number of patches this PR has	#
# $1: the patch id				#
# Return: The number of patches			#
#################################################
number_of_patches()
{
	local attach_size
	local bug_id
	bug_id="${1}"

	attach_size=$(${CURL_CMD}/"${bug_id}"/attachment \
		| ${JQ} ".bugs.\"${bug_id}\"[].is_patch  == 1" | wc -l)

	echo "${attach_size}"
}

#################################################
# Download patch from PR. Assumes there is	#
# exactly one patch to download			#
# $1: the PR number				#
# Return the name of the patch in the		#
# local filesystem				#
#################################################
download_patch()
{
	local file_name
	local pr
	pr="${1}"
	file_name="${pr}".patch

	${CURL_CMD}/"${pr}"/attachment \
			| ${JQ} ".bugs.\"${pr}\"[0].data" \
			| sed -e 's/"//g' \
			| b64decode -r > "${file_name}"

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

	patch -p"${strip_n}" -E -i ../../"${patch_file}" &> /dev/null

	if [[ ${?} -ne 0 ]]; then
		echo 1
		return
	fi

	# After applying the patch, we should delete the .orig
	# so portlint does not get mad
	find "${pr_dir}" -name '*.orig' -delete

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
		fi
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
	local success

	pr="${1}"
	
	port_dir=$(checkout_port "${pr}")
	patch_file=$(download_patch "${pr}")
	success=$(apply_patch "${pr}" "${patch_file}")

	if [[ "${success}" -ne 0 ]]; then
		echo "Patch does not apply"
		push_to_report "PATCH_FAILED"
		if [[ $(file "${patch_file}" | grep CRLF) -eq 0 ]]; then
			push_to_report "PATCH_HAS_CRLF"
		fi
		return
	fi

	# OK, so we could apply the patch. Let's run some checks
	# on the port

	run_linters "${port_dir}"
}
