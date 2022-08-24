#!/usr/bin/env bash

# This script populates a key with the right value in the named file(s).
# Expected args are one or more files to populate.
# Expectation is that the file is a text file where key-value assignments are delimited with a colon (:).

## Main

if [ ! -e $(dirname $0)/populate_value.sh ]; then
    echo "Error: missing file populate_value.sh containing required function. It should be in the same directory as this script."
    exit 1
fi

source $(dirname $0)/populate_value.sh

# Initialize just in case env var exists
POP_VAL=""
POP_FILE=""
NAMESPACE="openldap"

# This is the static target key to patch for this script:
POP_KEY="lc_ldap_server"

if [ ${#@} -eq 0 ]; then
    echo "Error: target files to update with correct ${POP_KEY} value should be input as arguments."
    exit 1
fi

# Check that we have oc command available
which oc 2>&1 > /dev/null
if [ $? -eq 1 ]; then
    echo "Error: 'oc' command not found in PATH. This is needed to interact with the cluster."
    exit 1
fi

# Assuming one is authenticated to the cluster, this grabs the service found in the target namespace
# with a port that is named exactly "ldap-port" and clusterIP is a valid IP address:
POP_VAL=$(oc get services -n ${NAMESPACE} --output=json | jq '.items[] | select(.spec.ports[].name | test("^ldap-port$")) | select(.spec.clusterIP | test("^(([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5]).){3}.([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])$")) | .metadata.name' | tr -d '"')

# Make sure we have a valid value to patch with, and no ambiguity on which service to refer to:
if [[ -z ${POP_VAL} ]] ; then
    echo "Error: No value found for target key $POP_KEY."
    exit 1
elif [[ $(echo $POP_VAL | wc -w) -gt 1 ]]; then
    echo "Error: Multiple services with port '${POP_KEY}' (port 389)."
    exit 1
fi

# Complete the hostname:
POP_VAL="${POP_VAL}.${NAMESPACE}.svc.cluster.local"

## Update lc_ldap_server for the files supplied in the args:
for POP_FILE in $@; do
    if [ ! -e ${POP_FILE} ]; then
        echo "Error: target file ${POP_FILE} does not exist."
        exit 1
    else
        populate_value $POP_KEY $POP_VAL $POP_FILE
    fi
done
