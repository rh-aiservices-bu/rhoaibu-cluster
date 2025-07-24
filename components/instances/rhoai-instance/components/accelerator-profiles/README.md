## Accelerator Profiles

To configure accelerators for your data scientists to use in OpenShift AI, you must create an associated [accelerator profile](https://access.redhat.com/documentation/en-us/red_hat_openshift_ai_self-managed/2.9/html/working_on_data_science_projects/working-with-accelerators_accelerators#working-with-accelerator-profiles_accelerators).

### Work with GPU Nodes in OpenShift AI

Each GPU node needs to have a proper taint set in order to prevent workloads from being scheduled on them if they don't have specific tolerations. Those tolerations are set in the different accelerator profiles associated to each type of GPU.

* Taints in the Nodes should be set like this:

```yaml
  taints:
    - effect: NoSchedule
      key: nvidia.com/gpu
      value: NVIDIA-A10G-SHARED
```

* Corresponding tolerations in Accelerator Profiles are then set like this:

```yaml
  tolerations:
    - effect: NoSchedule
      key: nvidia.com/gpu
      value: NVIDIA-A10G-SHARED
```



NOTE: you should apply taints directly in the MachineSets to avoid the need to edit each Node definition, especially after scaling the MachineSet up. This will prevent unwanted Pods from being scheduled on a new Node before you have a chance to edit its configuration.

If the Toleration is not present in the Accelerator Profile, the workloads will not be scheduled on the nodes with the taint.

In this example, Workbenches that select other GPU types will not be scheduled on the nodes with the taint NVIDIA-A10G-SHARED.
