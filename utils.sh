#!/usr/local/bin/bash

#################################################
# Some random utils that do not belong		#
# elsewhere					#
#################################################

source config.sh

#################################################
# Checks out a port directory from repo		#
# $1: pr number					#
# Return: path of the checked out port		#
#################################################
checkout_port()
{
	local port
	local pr
	pr="${1}"		
	port=$(get_port_name)

	target="${WRKDIR}"/"${pr}"
#echo "Checking out ${port} in ${target}"
	rm -rf "${target}" && mkdir "${target}" && cd "${target}"
	svn co "${PORTS_REPO_URL}"/"${port}" "${port}" &> /dev/null

	echo "${target}"/"${port}"
}

get_pr()
{
	local pr_raw
	pr_raw=$(${CURL_CMD}"/${1}")
	for field in ${FIELDS};do
		value=$(echo "${pr_raw}" | jq ".bugs[0].${field}")
		# Assign value removing double quotes
		data["${field}"]=${value//\"/}
	done

	if [[ "${data["Attachments"]}" -ne 0 ]]; then
		# This pr has attachments, let's get
		# the last one
		data["PatchID"]=$(echo "${pr_raw}" | grep "Created attachment" \
			| cut -f3 -d" " | sort -run | head -1)
	fi
}

get_port_name()
{
	local port

	port=$(echo "${data["summary"]}" \
		| grep -E -o '([[:alnum:]]|-|_)*/([[:alnum:]]|-|_)*')

	echo "${port}"
}

#################################################
# Gets the strip number from the patch passed 	#
# as parameter so we can apply the patch from 	#
# the current directory				#
# $1: patch file name				#
#################################################
get_strip_level()
{
	local patch_file
	local ref_line
	local ret
	local strip_level

	patch_file="${1}"
	ref_line="$(grep -E '\+\+\+ ([[:alnum:]])+' "${patch_file}" | head -n1)"

	strip_level=$(echo "${ref_line}" | cut -f2 -d" " \
		| grep -F -o / | wc -l)

	# if the patch we are dealing with is about a patch in files/
	# then we need to substract one to the p level. For instance, 
	# a patch like net-im/6cord/Makefile and other like
	# for net-im/6cord/files/patch.patch would return 2 for both.

	ret=$(echo "${ref_line}"| grep 'files/')

	if [[ -n "${ret}" ]]; then
		strip_level=$(("${strip_level}" - 1))
	fi

	echo "${strip_level}"
}
