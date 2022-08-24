#!/usr/bin/env bash

# This function populates a key with the right value in the named file(s).
# Expected args are one or more files to populate.
# Expectation is that the file is a text file where key-value assignments are delimited with a colon (:).

function populate_value()
{
    # These will take from local variables that should be set before calling this function:
    POP_KEY=$1
    POP_VAL=$2
    POP_FILE=$3

    if [[ -z ${POP_KEY} ]] || [[ -z ${POP_VAL} ]] || [[ -z ${POP_FILE} ]] ; then
        echo "Error: Incomplete input vars."
        echo "Please provide all three of the expected vars: POP_KEY, POP_VAL, and POP_FILE."
        echo "This script populates the key with the given value in the named file."
        exit 1
    fi

    if [ ! -e ${POP_FILE} ]; then
        echo "Error: target file ${POP_FILE} does not exist."
        exit 1
    fi

    if [ $(grep -c ${POP_KEY} ${POP_FILE}) -eq 0 ] ; then
        echo "Warning: target key '${POP_KEY}' not found in given file '${POP_FILE}'. Nothing to do."
    else
        # This form of sed should work on both Linux (GNU sed) and Darwin/MacOS.
        sed -i'.bak' -e 's/'${POP_KEY}:' .*/'${POP_KEY}': "'${POP_VAL}'"/' $POP_FILE && rm ${POP_FILE}.bak
    fi
}

