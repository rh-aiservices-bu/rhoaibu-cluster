#!/usr/bin/env bash

echo "## Patching the OpenShift API with the new certificates"
CERT_MANAGER_NAMESPACE="cert-manager-operator"
API_HOST_NAME=$(oc get secret openshift-api-certificate -n $CERT_MANAGER_NAMESPACE -o jsonpath='{.metadata.annotations.cert-manager\.io/common-name}')
echo $API_HOST_NAME
if oc get secret openshift-api-certificate -n $CERT_MANAGER_NAMESPACE; then
  oc get secrets openshift-api-certificate -n $CERT_MANAGER_NAMESPACE -o json | jq 'del(.metadata["namespace","creationTimestamp","resourceVersion","selfLink","uid","annotations"])' | oc apply -n openshift-config -f -
  oc patch apiserver cluster --type=merge -p '{"spec":{"servingCerts": {"namedCertificates": [{"names": ["'$API_HOST_NAME'"], "servingCertificate": {"name": "openshift-api-certificate"}}]}}}'
else
  echo "Could not execute sync as secret 'openshift-api-certificate' in namespace 'openshift-config' does not exist, check status of CertificationRequest"
  exit 1
fi

echo "## Patching the OpenShift Ingress with the new certificates"
CERT_MANAGER_NAMESPACE="cert-manager-operator"
if oc get secret openshift-wildcard-certificate -n $CERT_MANAGER_NAMESPACE; then
  oc get secrets openshift-wildcard-certificate -n $CERT_MANAGER_NAMESPACE -o json | jq 'del(.metadata["namespace","creationTimestamp","resourceVersion","selfLink","uid","annotations"])' | oc apply -n openshift-ingress -f -
  oc patch ingresscontroller default -n openshift-ingress-operator --type=merge --patch='{"spec": { "defaultCertificate": { "name": "openshift-wildcard-certificate" }}}'
else
  echo "Could not execute sync as secret 'openshift-wildcard-certificate' in namespace 'openshift-ingress' does not exist, check status of CertificationRequest"
  exit 1
fi

