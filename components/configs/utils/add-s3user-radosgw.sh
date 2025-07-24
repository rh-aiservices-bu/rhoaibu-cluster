#!/bin/bash


oc exec -n openshift-storage $(oc get pod -n openshift-storage -l \ 
app=rook-ceph-tools -o jsonpath='{.items[0].metadata.name}') -- radosgw-admin user create --uid="s3user" --display-name="S3 ODF User" --system
