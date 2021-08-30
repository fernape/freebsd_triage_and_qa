#!/usr/local/bin/bash

source $(dirname ${BASH_SOURCE[0]})/templates.sh
source $(dirname ${BASH_SOURCE[0]})/utils.sh

#################################################
# File with all the ckecker functions		#
# related to PR and bugzilla themselves		#
#						#
#################################################

#################################################
# Check if port exists				#
#################################################
check_port_exists()
{
	local port
	port=$(get_port_name)

	if [[ ! -d "${PORTS_BASE}/${port}" ]]; then
		echo Port "${port}" does not exist
	fi
}

#################################################
# Check if reporter is the same as maintainer	#
# and if so, check if the patch has the 	#
# maintainer-approval flag set or the		#
# maintainer-feedback flag in the PR		#
# It assumes there is only one patch attached	#
#################################################
check_reporter_is_maintainer()
{
	local has_flag
	local maintainer
	local new_port
	local port
	local reporter

	new_port=$(echo "${data["summary"]}" | grep -i 'new port')

	if [[ -n "${new_port}" ]]; then
		# This is a new port, no need to check anymore
		return
	fi

	reporter=${data["creator"]}
	port=$(get_port_name)
	maintainer=$(make -C "${PORTS_BASE}/${port}" -VMAINTAINER)

	if [[ "${reporter}" == "${maintainer}" ]]; then
		has_flag="$(has_maintainer_flag ${data["pr_id"]})"
		if [[ "${has_flag}" -eq 0 ]]; then
			echo Reporter is maintainer: \
			"${reporter}" vs "${maintainer}" \
			but no mantainer-flag is set
			push_to_report "SET_MAINTAINER_APPROVAL"
		fi
		if [[ ! -z "${data["maintainer-feedback"]}" ]]; then
			echo Reporter is maintainer and sets maintainer-feedback
			push_to_report "CLEAR_MAINTAINER_FEEDBACK"
		fi
	fi
}

#################################################
# Check if reporter is commiter and so, we can	#
# auto assign the PR				#
#################################################
check_reporter_is_committer()
{
	local is_commiter
	is_commiter=$(echo "${data["creator"]}" | grep -i '@FreeBSD.org')

	if [[ -n "${is_commiter}" && "${is_commiter}" != "${data["assigned_to"]}" ]]; then
		echo -n Reporter is commiter and does not auto assign:
		echo "${data["creator"]}"
		push_to_report "REPORTER_IS_COMMITTER"
	fi
}


#################################################
# Check for tags and other things in title	#
# that are not necessary			#
#################################################
check_title()
{
	local new_port
	local remove_words
	local superfluous
	local tags

	remove_words="commit|current|from|patch|port|tag|version|->"
	tags=$(echo "${data["summary"]}" \
			| grep -E -o '\[([[:alnum:]]| |-)*\]')
	superfluous=$(echo "${data["summary"]}" \
			| grep -E -i -o -w "${remove_words}")
	new_port=$(echo "${tags}" | grep -i 'new port')

	if [[ -n "${new_port}" ]]; then
		# This is a new port, no need to check anymore
		return
	fi
	
	if [[ -n "${tags}" ]]; then
		echo Tags usage is deprecated: "${tags}"
		push_to_report "TAGS"
	fi
	
	if [[ -n "${superfluous}" ]]; then
		push_to_report "BOGUS_TITLE"
	fi
}

#################################################
# Check if this is an update and there is a 	#
# changelog					#
#################################################
check_for_changelog()
{
	local is_update
	is_update=$(echo "${data["summary"]}" | grep -E -i 'update|upgrade')

	if [[ -n "${is_update}" && -z "${data["url"]}" ]]; then
		echo Port udpate without changelog
		push_to_report "CHANGELOG"
	fi
}


#################################################
# Check for words in the changelog that might 	#
# indicate this is a candidate to be MFHed	#
#################################################
check_changelog_content()
{
	local bug_words
	local changelog_txt
	local changelog_url
	local res
	local sec_words

	bug_words="bug|crash"
	sec_words="cve|vulnerability"
	changelog_url="${data["url"]}"


	if [[ -n "${changelog_url}" ]]; then
		changelog_txt=$(${CURL} -s "${changelog_url}")
		res=$(echo "${changelog_txt}" | grep -E -i "${bug_words}")
		if [[ -n "${res}" ]]; then
			push_to_report "MFH_BUGFIX"
		fi
		res=$(echo "${changelog_txt}" | grep -E -i "${sec_words}")
		if [[ -n "${res}" ]]; then
			push_to_report "MFH_SECURITY"
		fi
	fi
}
