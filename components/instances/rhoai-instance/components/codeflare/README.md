## Codeflare and Distributed Workloads

Distributed workloads enable data scientists to use multiple cluster nodes in parallel for faster and more efficient data processing and model training. The CodeFlare framework simplifies task orchestration and monitoring, and offers seamless integration for automated resource scaling and optimal node utilization with advanced GPU support.

> The kustomization.yaml of this component only enables the default-flavor.yaml, but not the ClusterQueue and the LocalQueue because depends strongly on the environment provided. Please follow the [official CodeFlare documentation](https://access.redhat.com/documentation/en-us/red_hat_openshift_ai_self-managed/2.9/html/working_with_distributed_workloads/configuring-distributed-workloads_distributed-workloads).