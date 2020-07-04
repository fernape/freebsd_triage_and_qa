#!/usr/local/bin/bash

source config.sh
source patch_checker.sh
source pr_checkers.sh
source utils.sh

if [[ ${#} -eq 0 ]]; then
	echo Usage "${0} <pr>"
	exit 0
fi

#for field in ${FIELDS};do
#	echo "${field}="${data["${field}"]}
#done


echo -e "\n\n"
echo -------------
echo TRIAGE CHECKS
echo -------------

get_pr "${1}"

check_reporter_is_maintainer
check_reporter_is_committer
check_title
check_for_changelog
check_port_exists

if [[ "${data["Attachments"]}" -ne 0 ]]; then
	# This pr has attachments, let's try to apply
	# patches.
	try_patch "${1}" "${data["PatchID"]}"
fi
