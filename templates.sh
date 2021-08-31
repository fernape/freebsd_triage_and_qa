# Messages obtained from https://wiki.freebsd.org/Bugzilla/TriageTraining

#################################
# Message templates		#
#################################
declare -A messages

messages["MFH_BUGFIX"]="^Triage: Bugfix release, merge to quarterly branch."
messages["MFH_SECURITY"]="^Triage: Security release, merge to quarterly branch."
messages["MFH_RELEVANT"]="^Triage: Are quarterly users affected? Merge to quarterly (MFH) candidate."
messages["LINTERS"]="^Triage: Please confirm this change passes QA (portlint, poudriere at least).
--
https://www.freebsd.org/doc/en/books/porters-handbook/testing.html"
messages["CHANGELOG"]="^Triage: If there is a changelog or release notes URL available for this version, please add it to the URL field."
messages["REQUEST_APPROVAL"]="^Triage: Please set the maintainer-approval attachment flag (to ?) and set the requestee field to the e-mail address of the maintainer to ask for maintainer approval.
--
Attachment -> Details -> maintainer-approval [?]"
messages["SET_MAINTAINER_APPROVAL"]="^Triage: Please set the maintainer-approval attachment flag (to +) on patches for ports you maintain to signify approval.
--
Attachment -> Details -> maintainer-approval [+]"
messages["CLEAR_MAINTAINER_FEEDBACK"]="^Triage: Maintainer-feedback flag (+) not required unless requested (?) first."
messages["REPORTER_IS_COMMITTER"]="^Triage: Reporter is committer, assign accordingly."
messages["UNABLE_REPRODUCE"]="^Triage: If this is still reproducible, please re-open this issue with additional information and steps to reproduce if not already provided."
messages["COMMITTER_RESOLVING"]="^Triage: Assign to committer resolving"
messages["TAGS"]="^Triage: [tags] in issue Titles are deprecated."
messages["GENERAL_SUPPORT"]="^Triage: Thank you for your report. Our issue tracker is used for issues identified to be bugs and enhancements.
--
If your issue is isolated to be a bug and is reproducible on an up-to-date and supported FreeBSD version, please re-open this issue with additional information and steps to reproduce."

#### Cusctom mesages not present in the wiki ####
messages["GH_TAGTUPLE"]="Q/A: DIST/PORTVERSION has been updated but GH_TAGNAME/TUPLE has not been updated"
messages["PATCH_FAILED"]="Q/A: patch did not apply cleanly. Would you mind checking it?"
messages["PATCH_HAS_CRLF"]="Patch contains CRLF terminators. If you pasted it in bugzilla try to upload it as an attachment."
messages["REMOVE_PORTREVISION"]="Q/A: PORTREVISION should be removed"
messages["BOGUS_TITLE"]="^Triage: Simplifying title"
messages["HTTP_IN_PKG_DESCR"]="^Triage: WWW uses http. Can we use https?"
messages["PORTEPOCH_REMOVAL"]="^Triage: Is removing PORTEPOCH truly intended?"

#################################
# Action templates		#
#################################
declare -A actions

actions["BOGUS_TITLE"]="Reword title"
actions["CLEAR_MAINTAINER_FEEDBACK"]="Set: maintainer-feedback: X "
actions["COMMITTER_RESOLVING"]="Assignee: <committer>
Status: In Progress"
actions["GENERAL_SUPPORT"]="Assignee: <you>
Status: Closed
Resolution: Not A Bug"
actions["LINTERS"]="Keywords: needs-qa "
actions["MFH_BUGFIX"]="Set: merge-quarterly: ? "
actions["MFH_RELEVANT"]="Set: merge-quarterly: ? "
actions["MFH_SECURITY"]="Keywords: security
CC: ports-secteam
Priority: High
Severity: Affects Many People
Set: merge-quarterly: ? "
actions["REPORTER_IS_COMMITTER"]="Assignee: <reporter>"
actions["TAGS"]="Remove tag (except [NEW PORT]) from summary"
actions["UNABLE_REPRODUCE"]="Assignee: <yourself>
Status: Closed
Resolution: <as appropriate>"
