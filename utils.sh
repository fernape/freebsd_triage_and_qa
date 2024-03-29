#!/usr/local/bin/bash

#################################################
# Some random utils that do not belong		#
# elsewhere					#
#################################################

source $(dirname ${BASH_SOURCE[0]})/config.sh

#################################################
# Creates a branch for the pr			#
# $1: pr number					#
# Return: path of the checked out port		#
#################################################
create_pr_branch()
{
	local changes
	local cur_branch
	local port
	local pr
	pr="${1}"		
	port=$(get_port_name)

	cur_branch=$(git branch --show-current)
	if [[ "${cur_branch}" != "main" ]]; then
		printf "Refusing to branch from other than 'main'\n"
		exit 1
	else
		# We are in main. Ensure this is clean before
		# branching off
		changes=$(git status --porcelain)
		if [[ -z "${changes}" ]]; then
			# Branch is clean
			git checkout -b "pr${pr}-${port}"
		else
			printf "Branch is not clean\n"
			exit 1
		fi
	fi
	
	echo "${WRKDIR}/${port}"
}

#################################################
# Gets and parses a PR				#
# $1: The PR id					#
# Result: fill data hash map with fields in PR	#
#################################################
get_pr()
{
	local pr_id
	local pr_raw

	pr_id="${1}"
	pr_raw=$(${CURL_CMD}"/${1}")
	for field in ${FIELDS};do
		value=$(echo "${pr_raw}" | jq ".bugs[0].${field}")
		# Assign value removing double quotes
		data["${field}"]=${value//\"/}
	done

	data["maintainer-feedback"]=$(echo "${pr_raw}" \
		| jq ".bugs[0].flags[].name" | grep "maintainer-feedback")

	data["pr_id"]="${1}"
}

get_port_name()
{
	local port

	port=$(echo "${data["summary"]}" \
		| grep -E -o '([[:alnum:]]|-|_)*/([[:alnum:]]|-|_|\.)*')

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
	ref_line="$(grep -E '\+\+\+ (\.|/|[[:alnum:]])+' "${patch_file}" | head -n1)"

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

#################################################
# Returns true if the attachment of the PR has	#
# the maintainer-flag set.			#
# It assumes one patch attached only		#
# $1: PR id					#
# Return: 1 if flag is set, 0 otherwise		#
#################################################

has_maintainer_flag()
{
	local flags
	local pr

	pr="${1}"

	flags=$(${CURL_CMD}/"${pr}"/attachment \
		| ${JQ} ".bugs.\"${pr}\"[] | select(.is_obsolete == 0) | select(.is_patch == 1) |.flags[0].status" \
			| sed -e 's/"//g')

	if [[ "${flags}" == "+" ]]; then
		echo 1
	else
		echo 0
	fi
}


#################################################
# Push actions and messages to the stack so	#
# they can be printed later			#
# $1: optional key for the messsages and actions#
# hash						#
# Globals: msg_stack, act_stack, messages,	#
# actions					#
#################################################
push_to_report()
{
	local key
	local text

	key="${1}"

	# If the key is not found, we add the text verbatim to the msg_stack
	text=("${messages["${key}"]}")
	if [[ -n "${text}" ]]; then
		msg_stack+=("${text}")
	else
		msg_stack+=("${key}")
	fi

	# Actions never have an extra message
	text=("${actions["${key}"]}")
	if [[ -n "${text}" ]]; then
		act_stack+=("${text}")
	fi
}


#################################################
# Print the final report with the messages and	#
# the actions					#
# Globals: msg_stack, act_stack			#
#################################################
print_report()
{
	echo -e "\n---------- REPORT ---------- "
	if [[ ${#msg_stack[@]} -ne 0 ]]; then
		echo "Messages:"
		printf "%s\n\n" "${msg_stack[@]}"
	fi

	echo -e "\nThanks!"

	if [[ ${#act_stack[@]} -ne 0 ]]; then
		echo -e "\nActions:"
		# Filter in case there are redundant actions
		printf "%s\n\n" "${act_stack[@]}" | sort -u
	fi

}
