## Cluster Certificates
Cluster Certificates are generated and controlled automatically (almost) by Cert-Manager based on the Cert-Manager Operator.

**NOTE:** The configuration currently lives in another [repository](https://github.com/rh-aiservices-bu/rh-aiservices-bu-bootstrap.git).

## Renew Certificates in OpenShift Clusters for API and Ingress (*apps)

We have two options to renew certificates using OpenShift:

* [Automatic Reissuance triggered by expiry (renewal) with Cert-Manager](https://cert-manager.io/docs/usage/certificate/#reissuance-triggered-by-expiry-renewal)
* [Renew Certificates triggered by user actions (manually) with Cert-Manager and cmctl](https://cert-manager.io/docs/usage/certificate/#reissuance-triggered-by-user-actions)

> IMPORTANT: In both cases, the certificates need to trigger a job that copies the certificates from the `cert-manager-operator` to the proper namespaces and patches the ingress and API to use the renewed certificates.

### Automatic Reissuance triggered by expiry (renewal) with Cert-Manager

By default, the renewal of the certificates for API and Ingress (*.apps) is set up to be triggered automatically every 75 days (1800h) and defined in the `Certificate` CR:

```bash
$ oc get certificate openshift-api -o jsonpath='{.spec.renewBefore}'
1800h
```

However, it is still necessary to copy the renewed certificates to the proper namespaces `openshift-ingress` and `openshift-config` and patch the API and Ingress pods to use the renewed certs instead of the older ones loaded.

There are two cronjobs enabled (for now in Dev):
* [One for the API](../../instances/cert-manager-instance/openshift-api-certificate/patch-cluster-api-cert-cronjob.yaml)
* [One for the Ingress](../../instances/cert-manager-instance/openshift-wildcard-certificate/patch-cluster-wildcard-cert-cronjob.yaml)

but they are calculated based on some predictions, which could fail.

#### Trigger copy and patch for Certificates using Jobs

In case they are not working properly, to trigger the copy and patch of the new certificates, execute:

```bash
kubectl apply -n cert-manager-operator -f components/instances/cert-manager-instance/openshift-api-certificate/patch-cluster-api-cert-job.yaml
kubectl apply -n cert-manager-operator -f components/instances/cert-manager-instance/openshift-wildcard-certificate/patch-cluster-wildcard-cert-job.yaml
```

NOTE: The jobs are automatically cleaned up after 1000 seconds (approximately 17 minutes) to allow checking, but also to ensure proper cleanup using the `ttlSecondsAfterFinished: 1000` [TTL mechanism for finished jobs](https://kubernetes.io/docs/concepts/workloads/controllers/job/#ttl-mechanism-for-finished-jobs).

* After a couple of minutes, check the Validity of your currently installed certificates
```bash
BASE_DOMAIN=$(kubectl get dns cluster -o jsonpath='{.spec.baseDomain}')
echo "##For OpenShift Wildcard Ingress"
echo | openssl s_client -connect api.$BASE_DOMAIN:6443 | openssl x509 -noout -text | grep -A2 Validity
echo "## For OpenShift Wildcard Ingress"
echo | openssl s_client -connect test.apps.$BASE_DOMAIN:443 | openssl x509 -noout -text | grep -A2 Validity
```

### Renew Certificates in OpenShift clusters Manually

To manually renew the API and Wildcard certificates before the renewal period (set up to 120 days), as mentioned in the official documentation on [Reissue certificates automatically](https://cert-manager.io/docs/usage/certificate/#reissuance-triggered-by-user-actions), we need to check the status of the current certificates.

* Check the Validity of your currently installed certificates
```bash
BASE_DOMAIN=$(kubectl get dns cluster -o jsonpath='{.spec.baseDomain}')
echo "## For OpenShift Wildcard Ingress"
echo | openssl s_client -connect api.$BASE_DOMAIN:6443 | openssl x509 -noout -text | grep -A2 Validity
echo "## For OpenShift Wildcard Ingress"
echo | openssl s_client -connect test.apps.$BASE_DOMAIN:443 | openssl x509 -noout -text | grep -A2 Validity
```

* Use the [cmctl](https://cert-manager.io/docs/reference/cmctl/#installation) command to check the currently issued certificates located in the `cert-manager-operator`:

```bash
oc project cert-manager-operator
cmctl status certificate openshift-api
cmctl status certificate openshift-wildcard
```

* Manually renew the certificates for the openshift-api and openshift-wildcard:

```bash
cmctl renew -n cert-manager-operator openshift-api
cmctl renew -n cert-manager-operator openshift-wildcard
```

* After a couple of minutes, check again by running the following commands:

```bash
cmctl status certificate openshift-api
cmctl status certificate openshift-wildcard
```

Some output like this will indicate that the renewal has been executed successfully:

```md
cmctl status certificate openshift-wildcard

Name: openshift-wildcard
Namespace: cert-manager-operator
Created at: 2024-07-18T17:59:31+02:00
Conditions:
    Ready: True, Reason: Ready, Message: Certificate is up to date and has not expired
DNS Names:
- *.apps.dev.rhoai.xxx
Events:
    Type    Reason     Age                    From                                       Message
    ----    ------     ----                   ----                                       -------
    Normal  Reused     3m38s (x2 over 2d21h)  cert-manager-certificates-key-manager      Reusing private key stored in existing Secret resource "openshift-wildcard-certificate"
    Normal  Requested  3m38s                  cert-manager-certificates-request-manager  Created new CertificateRequest resource "openshift-wildcard-5"
    Normal  Issuing    3m36s (x2 over 2d21h)  cert-manager-certificates-issuing          The certificate has been successfully issued
Issuer:
    Name: letsencrypt-prod
    Kind: ClusterIssuer
    Conditions:
        Ready: True, Reason: ACMEAccountRegistered, Message: The ACME account was registered with the ACME server
    Events:  <none>
Secret:
    Name: openshift-wildcard-certificate
    Issuer Country: US
    Issuer Organisation: Let's Encrypt
    Issuer Common Name: R11
...
```

* The certificates are located in the cert-manager-operator namespace, stored as secrets:

```bash
kubectl get secrets -n cert-manager-operator | grep -E "openshift|certificate"
openshift-api-certificate                                  kubernetes.io/tls                     2      47d
openshift-wildcard-certificate                             kubernetes.io/tls                     2      47d
```

However, they are not copied automatically to the proper namespace, and neither patched to be used by the OpenShift Ingress and OpenShift Kubernetes API, so we need to run a job: 

```bash
kubectl apply -n cert-manager-operator -f components/instances/cert-manager-instance/openshift-api-certificate/patch-cluster-api-cert-job.yaml
kubectl apply -n cert-manager-operator -f components/instances/cert-manager-instance/openshift-wildcard-certificate/patch-cluster-wildcard-cert-job.yaml
```

NOTE: The jobs are automatically cleaned up after 1000 seconds (approximately 17 minutes) to allow checking, but also to ensure proper cleanup using the `ttlSecondsAfterFinished: 1000` [TTL mechanism for finished jobs](https://kubernetes.io/docs/concepts/workloads/controllers/job/#ttl-mechanism-for-finished-jobs).

* After a couple of minutes, check the Validity of your currently installed certificates
```bash
BASE_DOMAIN=$(kubectl get dns cluster -o jsonpath='{.spec.baseDomain}')
echo "##For OpenShift Wildcard Ingress"
echo | openssl s_client -connect api.$BASE_DOMAIN:6443 | openssl x509 -noout -text | grep -A2 Validity
echo "## For OpenShift Wildcard Ingress"
echo | openssl s_client -connect test.apps.$BASE_DOMAIN:443 | openssl x509 -noout -text | grep -A2 Validity
```
