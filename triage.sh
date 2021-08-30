#!/usr/local/bin/bash

source $(dirname ${BASH_SOURCE[0]})/config.sh
source $(dirname ${BASH_SOURCE[0]})/change_analyzer.sh
source $(dirname ${BASH_SOURCE[0]})/patch_checker.sh
source $(dirname ${BASH_SOURCE[0]})/pr_checkers.sh
source $(dirname ${BASH_SOURCE[0]})/utils.sh

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

pr="${1}"
get_pr "${pr}"

has_patches=$(number_of_patches "${pr}")

check_reporter_is_committer
check_title
check_for_changelog
check_changelog_content
check_port_exists

check_reporter_is_maintainer
if [[ "${has_patches}" -eq 1 ]]; then
	# This pr has attachments, let's try to apply
	# patches.
	try_patch "${1}"

	port=$(get_port_name)
	analyze_changes "${WRKDIR}"/"${port}"
else
	if [[ "${has_patches}" -gt 1 ]]; then
		echo "Multiple patches in PR"
	else
		echo "No patches found in PR"
	fi
fi

print_report
