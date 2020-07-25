#!/usr/local/bin/bash

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
#################################################
check_reporter_is_maintainer()
{
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
	port=$(echo "${data["summary"]}" \
			| grep -E -o '([[:alnum:]]|-|_)*/([[:alnum:]]|-|_)*')
	maintainer=$(make -C "${PORTS_BASE}/${port}" -VMAINTAINER)

	if [[ "${reporter}" == "${maintainer}" ]]; then
		echo Reporter is maintainer: "${reporter}" vs "${maintainer}"
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

	remove_words="commit|current|tag|version|->"
	tags=$(echo "${data["summary"]}" \
			| grep -E -o '\[([[:alnum:]]| )*\]')
	superfluous=$(echo "${data["summary"]}" \
			| grep -E -i -o -w "${remove_words}")
	new_port=$(echo "${tags}" | grep -i 'new port')

	if [[ -n "${new_port}" ]]; then
		# This is a new port, no need to check anymore
		return
	fi
	
	if [[ -n "${tags}" ]]; then
		echo Tags usage is deprecated: "${tags}"
	fi
	
	if [[ -n "${superfluous}" ]]; then
		echo Superfluous words in title: "${superfluous}"
	fi
}

check_for_changelog()
{
	local is_update
	is_update=$(echo "${data["summary"]}" | grep -E -i 'update|upgrade')

	if [[ -n "${is_update}" && -z "${data["url"]}" ]]; then
		echo Port udpate without changelog
	fi
}
