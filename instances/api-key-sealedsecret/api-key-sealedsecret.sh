#!/usr/bin/env bash

# Creates sealed secret YAML with the (IBM/AWS/whatever) Cloud API key"
#
# 
if [[ -z ${API_KEY} ]] ; then
  echo "Please provide the API_KEY env var which will then go into the sealedsecret"
  exit 1
fi

API_KEY=${API_KEY}

# These two are either provided or default to "sealed-secrets"
SEALED_SECRET_NAMESPACE=${SEALED_SECRET_NAMESPACE:-sealed-secrets}
SEALED_SECRET_CONTOLLER_NAME=${SEALED_SECRET_CONTOLLER_NAME:-sealed-secrets}

# Create Kubernetes Secret yaml in namespace "kube-system"
oc create secret generic secrets-mgr-ap-key -n kube-system \
   --from-literal apiKey=${API_KEY} \
   --dry-run=client -o yaml > delete-api-key-secret.yaml

# Encrypt the secret using kubeseal and private key from the cluster
kubeseal -n kube-system --controller-name=${SEALED_SECRET_CONTOLLER_NAME} --controller-namespace=${SEALED_SECRET_NAMESPACE} -o yaml < delete-api-key-secret.yaml > api-key-secret.yaml

# NOTE, do not push delete-api-key-secret.yaml into git!
rm delete-api-key-secret.yaml
