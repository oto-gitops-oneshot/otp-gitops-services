#!/usr/bin/env bash

# This script populates specific jinja vars with the right values in the named file(s).
# The expectation is that the file is a text file with the right jinja vars to fill in.
# The expected arg is just the namespace where the ICP4ACluster is to be found.

function usage()
{
cat<<EOM

Usage:

  $0 -n NAMESPACE -f file1 [file2 ..[ fileN]]

EOM
}

if [ ${#1} -eq 0 ] ; then
  usage
  exit 0
fi

while getopts ":n:f:h" opt; do
    case $opt in
        f)
            FILES+=("$OPTARG");
            ;;
        n)
            NAMESPACE=$OPTARG;
            ;;
        h)
            usage;
            exit 0;
            ;;
        *)
            usage;
            exit 1;
            ;;
  esac
done

if [ ${FILES}x == 'x' ]; then
    echo "Error: required arg '-f <one or more target files>' is missing."
    exit 1
fi

if [ ${NAMESPACE}x == 'x' ]; then
    echo "Error: required arg '-n namespace' is missing."
    exit 1
fi

# Check that we have oc command available
which oc 2>&1 > /dev/null
if [ $? -eq 1 ]; then
    echo "Error: 'oc' command not found in PATH. This is needed to interact with the cluster."
    exit 1
fi

# The following jinja variables need to be patched with real values:
# 1. cp4ba_project_name <-- NAMESPACE, given arg
# 2. apps_endpoint_domain:
DOMAIN=$(oc describe console/cluster  | awk -F. '/Console URL/{for (i=2;i<NF;i++) printf("%s.",$i); print $NF}' | tr -d '"')
# 3. cp4ba_cr_meta_name:
icp4a_cluster=$(oc get ICP4ACluster -n ${NAMESPACE} |  awk '{if (NR==1) for(i=1;i<=NF;i++) if ($i=="NAME") column=i; if (NR>1) print $column}')
CP4BA_CR_META_NAME=$(oc get ICP4ACluster -n ${NAMESPACE} ${icp4a_cluster} -o jsonpath='{$.metadata.name}')

# Replacing the following jinja vars in the target file(s):
# 1. cp4ba_project_name <-- ${NAMESPACE}
# 2. apps_endpoint_domain <-- ${DOMAIN}
# 3. cp4ba_cr_meta_name <-- ${CP4BA_CR_META_NAME}

# Make sure we have a valid value to patch with, and no ambiguity on which service to refer to:
if [[ -z ${DOMAIN} ]] ; then
    echo "Error: No domain found from query sent (oc describe console/cluster)."
    exit 1
elif [[ $(echo $DOMAIN | wc -w) -gt 1 ]]; then
    echo "Error: Unexpected results from cluster query; was expecting a single value."
    exit 1
fi

# Update tm_job_url for the files supplied in the args:
for POP_FILE in "${FILES[@]}"; do
    if [ ! -e ${POP_FILE} ]; then
        echo "Error: target file ${POP_FILE} does not exist."
        exit 1
    else
        sed -i.bak -e 's/{{ *cp4ba_project_name *}}/'${NAMESPACE}'/;s/{{ *apps_endpoint_domain *}}/'${DOMAIN}'/;s/{{ *cp4ba_cr_meta_name *}}/'${CP4BA_CR_META_NAME}'/;' $POP_FILE && rm -f ${POP_FILE}.bak
    fi
done
