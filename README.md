# RHOAI BU Cluster Repository

[Private] Repository for deploying, managing, and updating the RHOAI BU Cluster

## Table of Contents

- [RHOAI BU Cluster Repository](#rhoai-bu-cluster-repository)
  - [Table of Contents](#table-of-contents)
  - [Components Managed by GitOps in the RHOAI Cluster](#components-managed-by-gitops-in-the-rhoai-cluster)
    - [Main Operators](#main-operators)
    - [Extra Operators](#extra-operators)
    - [Operator Instances](#operator-instances)
    - [Configs](#configs)
    - [Others](#others)
  - [How to deploy Cluster and Manage it with GitOps](#how-to-deploy-cluster-and-manage-it-with-gitops)
  - [How to develop and test changes in the RHOAI Cluster](#how-to-develop-and-test-changes-in-the-rhoai-cluster)

## Components Managed by GitOps in the RHOAI Cluster

### Main Operators

* [Openshift Cert Manager Operator](./components/operators/openshift-cert-manager-operator)
* [Openshift Data Foundation Operator](./components/operators/openshift-data-foundation-operator)
* [Nvidia Operator](./components/operators/nvidia-operator)
* [Nfd](./components/operators/nfd)
* [Kiali Operator](./components/operators/kiali-operator)
* [Devspaces](./components/operators/devspaces)
* [Openshift Gitops Operator](./components/operators/openshift-gitops-operator)
* [Openshift Pipelines Operator](./components/operators/openshift-pipelines-operator)
* [Openshift Serverless Operator](./components/operators/openshift-serverless-operator)
* [Openshift Service Mesh](./components/operators/openshift-service-mesh)
* [RHOAI Operator](./components/operators/rhoai-operator)
* [Web Terminal](./components/operators/web-terminal)
* [Authorino Operator](./components/operators/authorino-operator)
* [Openshift Lightspeed](./components/operators/openshift-lightspeed)
* [Openshift Virtualization](./components/operators/openshift-virtualization)
* [OpenShift Red Hat Build of OpenTelemetry Operator](./components/operators/openshift-opentelemetry-operator/)

### Extra Operators

* [Aikit Operator Instance](./components/instances/aikit-instance)
* [Ovms Operator Instance](./components/instances/ovms-instance)
* [Redis Enterprise Operator Instance](./components/instances/redis-enterprise-instance)
* [Starbust Operator Instance](./components/instances/starbust-instance)
* [Codeflare Operator Instance](./components/instances/codeflare-instance)
* [Pachyderm Operator Instance](./components/instances/pachyderm-instance)
* [Run Ai Operator Instance](./components/instances/run-ai-instance)

### Operator Instances

* [NFD Instance](./components/instances/nfd-instance)
* [RHOAI Instance](./components/instances/rhoai-instance)
* [OVMS Instance](./components/instances/ovms-instance)
* [Cert Manager Instance](./components/instances/cert-manager-instance)
* [ODF Instance](./components/instances/odf-instance)
* [NVIDIA Operator Instance](./components/instances/nvidia-instance)

### Configs

* [Cluster Certs](https://github.com/rh-aiservices-bu/rh-aiservices-bu-bootstrap)
* [Console Customizations](./components/configs/console)
* [Limit Ranges & ProjectTemplates](./components/configs/namespaces)
* [OAuth](./components/configs/oauth)
* [RBAC](./components/configs/rbac)

### Others

* [ArgoCD Projects](https://argoproj.github.io/argo-cd/operator-manual/declarative-setup/#projects)
* [Utils](./components/utils)

## How to deploy Cluster and Manage it with GitOps

* [Boostrap Cluster](bootstrap/README.md)
* [GitOps Components Managed in the RHOAI Cluster](docs/README.md)

## How to develop and test changes in the RHOAI Cluster

* [Develop and Test Changes](docs/develop-and-test-changes.md)

>IMPORTANT: Do NOT publish or make public this repository! It contains **sensitive** information and resources to manage the RHOAI BU Cluster.