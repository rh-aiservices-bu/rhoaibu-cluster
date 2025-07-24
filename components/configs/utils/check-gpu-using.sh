#!/bin/bash

replica_sets=$(oc get pods -A -o json | jq -r '.items[] | select(any(.spec.containers[].resources.requests; .["nvidia.com/gpu"] != null)) | .metadata.namespace as $ns | .metadata.ownerReferences[]? | select(.kind == "ReplicaSet") | "\($ns),\(.name)"' | sort -u)

echo "Namespace,ReplicaSet,Deployment"; echo "$replica_sets" | while IFS=, read -r namespace rs; do deployment=$(oc get rs -n $namespace $rs -o json | jq -r '.metadata.ownerReferences[]? | select(.kind == "Deployment") | .name // "No Deployment"'); echo "$namespace,$rs,$deployment"; done