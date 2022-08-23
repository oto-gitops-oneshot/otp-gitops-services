#!/usr/bin/env bash

# This script populates the key with the given value in the named file.
# Expected env var names: POP_KEY, POP_VAL, and POP_FILE
# Expectation is that the file is a text file where key-value assignments are delimited with a colon (:).

if [[ -z ${POP_KEY} ]] || [[ -z ${POP_VAL} ]] || [[ -z ${POP_FILE} ]] ; then
    echo "Error: Incomplete input env vars."
    echo "Please provide all three of the expected env var names: POP_KEY, POP_VAL, and POP_FILE."
    echo "This script populates the key with the given value in the named file."
    exit 1
fi

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
sed -i'.bak' -e 's/'${POP_KEY}:' .*/'${POP_KEY}': "'${POP_VAL}'"/' $POP_FILE && rm -f ${POP_FILE}.bak
