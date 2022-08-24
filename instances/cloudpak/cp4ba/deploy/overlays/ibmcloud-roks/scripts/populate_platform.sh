#!/usr/bin/env bash

# This script populates the key with the given value in the named file.
# Expected args are one or more files to populate.
# Expectation is that the file is a text file where key-value assignments are delimited with a colon (:).

function populate_value()
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
    sed -i'.bak' -e 's/'${POP_KEY}:' .*/'${POP_KEY}': "'${POP_VAL}'"/' $POP_FILE && rm ${POP_FILE}.bak
    
}

## Main

# Initialize just in case env var exists
POP_VAL=""
POP_FILE=""

# This is the static target key to patch for this script:
POP_KEY="sc_deployment_hostname_suffix"

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

# Assuming one is authenticated to the cluster, this grabs the Console URL found for the cluster console:
POP_VAL=$(oc describe console/cluster  | awk -F. '/Console URL/{for (i=2;i<NF;i++) printf("%s.",$i); print $NF}' | tr -d '"')

# Make sure we have a valid value to patch with, and no ambiguity on which service to refer to:
if [[ -z ${POP_VAL} ]] ; then
    echo "Error: No value found for target key $POP_KEY."
    exit 1
elif [[ $(echo $POP_VAL | wc -w) -gt 1 ]]; then
    echo "Error: Unexpected results from cluster query; was expecting a single value."
    exit 1
fi

# Complete the hostname:
POP_VAL="cp4ba.${POP_VAL}"

## Update sc_deployment_hostname_suffix for the files supplied in the args:
for POP_FILE in $@; do
    if [ ! -e ${POP_FILE} ]; then
        echo "Error: target file ${POP_FILE} does not exist."
        exit 1
    else
        populate_value
    fi
done
