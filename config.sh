#!/usr/local/bin/bash

#################################################
# Some config variables				#
#################################################

# curl executable
CURL=$(which curl)
# jq executable
JQ=$(which jq)
# Bugzilla REST URL
BUGZILLA_URL=https://bugs.freebsd.org/bugzilla/rest/bug
# Command invokation
CURL_CMD="${CURL} -s ${BUGZILLA_URL}"
# Where I have my ports
PORTS_BASE="/home/fernape/FreeBSD-repos/ports/"
# Ports repository URL
PORTS_REPO_URL="https://git.freebsd.org/ports.git"
# Working directory
WRKDIR=${PORTS_BASE}

# List of fields we will parse
FIELDS="summary classification url platform last_change_time
creator priority status assigned_to version product
keywords severity component target_milestone creation_time"

# Dictionary of pairs field - value
# where we have the data of the pr
declare -A data

# message stack
declare -a msg_stack

# actions stack
declare -a act_stack
