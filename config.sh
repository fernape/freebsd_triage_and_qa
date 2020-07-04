#!/usr/local/bin/bash

#################################################
# Some config variables				#
#################################################

# Bugz executable
BUGZ=$(which bugz)
# Bugzilla xml rpc URL
BUGZILLA_URL=https://bugs.freebsd.org/bugzilla/xmlrpc.cgi 
# Command invokation
BUGZ_CMD="${BUGZ} -b ${BUGZILLA_URL} --skip-auth"
# Where I have my ports
PORTS_BASE="/home/fernape/FreeBSD-repos/ports/head/"
# Ports repository URL
PORTS_REPO_URL="https://svn.freebsd.org/ports/head/"
# Working directory
WRKDIR=/tmp

# List of fields we will parse
FIELDS="Title CC classification URL OpSystem Updated
Reporter Hardware Priority Status AssignedTo Version Product
Keywords Severity Component Target Milestone Reported Attachments"

# Dictionary of pairs field - value
# where we have the data of the pr
declare -A data

