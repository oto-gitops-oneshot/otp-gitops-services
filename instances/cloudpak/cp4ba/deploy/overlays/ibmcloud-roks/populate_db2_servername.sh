#!/usr/bin/env bash

# This script populates the key with the given value in the named file.
# Expected args are files to populate with the db2 database_servername.
# Expectation is that the file is a text file where key-value assignments are delimited with a colon (:).

function populate_db_servername()
{
    if [[ -z ${POP_KEY} ]] || [[ -z ${POP_VAL} ]] || [[ -z ${POP_FILE} ]] ; then
        echo "Error: Incomplete input env vars."
        echo "Please provide all three of the expected env var names: POP_KEY, POP_VAL, and POP_FILE."
        echo "This script populates the key with the given value in the named file."
        exit 1
    fi

    # These will take from local variables that should be set before calling this function:
    POP_KEY=${POP_KEY}
    POP_VAL=${POP_VAL}
    POP_FILE=${POP_FILE}

    if [ ! -e ${POP_FILE} ]; then
        echo "Error: target file ${POP_FILE} does not exist."
        exit 1
    fi

    if [ $(grep -c ${POP_KEY} ${POP_FILE}) -eq 0 ] ; then
        echo "Warning: target key '${POP_KEY}' not found in given file '${POP_FILE}'. Nothing to do."
        exit 0
    fi

    # This form of sed should work on both Linux (GNU sed) and Darwin/MacOS.
    sed -i".bak" -e 's/'${POP_KEY}:' .*/'${POP_KEY}': "'${POP_VAL}'"/' $POP_FILE

    which oc 2>&1 > /dev/null
    if [ $? -eq 1 ]; then
        echo "Error: 'oc' command not found in PATH. This is needed to query the db2 service in the db2 namespace."
        exit 1
    fi
}

## Main
if [ ${#@} -eq 0 ]; then
    echo "Error: target files to update with correct database_servername value should be input as arguments."
    exit 1
fi

# This is the static target key to patch for this script:
POP_KEY="database_servername"

# Assuming one is authenticated to the cluster, this grabs service found in the 'db2' namespace with a port that is named "db2-server":
POP_VAL=$(oc get services -n db2 --output=json | jq '.items[] | select(.spec.ports[].name | contains("db2-server")) | .metadata.name' | tr -d '"')

if [[ -z ${POP_VAL} ]] ; then
    echo "Error: No servername found."
    exit 1
fi

# Complete the hostname:
POP_VAL="${POP_VAL}.db2.svc.cluster.local"

## Update database_servername for the files supplied in the args:
for POP_FILE in $@; do
    if [ ! -e ${POP_FILE} ]; then
        echo "Error: target file ${POP_FILE} does not exist."
        exit 1
    else
        populate_db_servername 
    fi
done
