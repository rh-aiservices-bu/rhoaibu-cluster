# Autoscaling in RHOAIBU Cluster

## GPU Usage Guidelines

> **⚠️ Important: Read Before Using GPU Resources**

### For Regular Users
- **Only use Tesla-T4-SHARED** GPU instances for regular workloads
- This provides **16GB VRAM** and is sufficient for most AI/ML development tasks
- These instances are shared resources and automatically scale based on demand

### For Internal/Restricted Usage
All other GPU types are **reserved for internal usage only**:
- **NVIDIA-A10G-SHARED** (24GB VRAM)
- **Tesla-T4-PRIVATE** (16GB VRAM)  
- **NVIDIA-A10G-PRIVATE** (24GB VRAM)

**If you require access to these restricted GPU resources**, please contact the **CAI team** with:
- Justification for the specific GPU requirement
- Expected usage duration
- Project/workload details

### How to Select GPUs in RHOAI

When creating workbenches or running notebooks in Red Hat OpenShift AI:

1. **For Regular Users**: Select the **"Medium GPU Card (NVIDIA T4 - 16 GB VRAM)"** accelerator profile
2. **For Internal Use**: Other accelerator profiles require CAI team approval
3. The selected accelerator profile will automatically provision the appropriate GPU resources from the Tesla-T4-SHARED pool

## Cluster Autoscaler

The Cluster Autoscaler is enabled in both the Dev and Prod clusters, allowing GPU instances to scale automatically based on demand. Currently, we have four GPU pools with the [following specifications](./base/autoscaling.yaml).

```yaml
- max: 4
  min: 0
  type: Tesla-T4-SHARED
- max: 2
  min: 0
  type: NVIDIA-A10G-SHARED
- max: 10
  min: 0
  type: Tesla-T4-PRIVATE
- max: 10
  min: 0
  type: NVIDIA-A10G-PRIVATE
```

## MachineSets

We currently have two types of GPU instances distributed across four MachineSets, all configured for autoscaling:

- **g5.2xlarge** with **A10G** (24GB VRAM) - **Internal Use Only**
- **g4dn.2xlarge** with **Tesla T4** (16GB VRAM) - **Regular Users: SHARED only**

These instances are distributed across four MachineSets per cluster:

- `worker-gpu-g4dn.2xlarge-private-REGION` - **LABEL:** Tesla-T4-PRIVATE ⚠️ *Internal Use Only*
- `worker-gpu-g4dn.2xlarge-REGION` - **LABEL:** Tesla-T4-SHARED ✅ *Available for Regular Users*
- `worker-gpu-g5.2xlarge-private-REGION` - **LABEL:** NVIDIA-A10G-PRIVATE ⚠️ *Internal Use Only*
- `worker-gpu-g5.2xlarge-us-east-1a` - **LABEL:** NVIDIA-A10G-SHARED ⚠️ *Internal Use Only*

## MachineAutoscaler

To enable autoscaling for the MachineSets, we use the **MachineAutoscaler**, which connects the **Cluster Autoscaler** with the MachineSets. We configure four MachineAutoscaler resources, each corresponding to the labels used in the MachineSets:

- [machineautoscaler-a10-shared.yaml](../autoscaling/overlays/multi-autoscaling-pool/rhoaibu-cluster-dev/machineautoscaler-a10-shared.yaml)
- [machineautoscaler-t4-shared.yaml](../autoscaling/overlays/multi-autoscaling-pool/rhoaibu-cluster-dev/machineautoscaler-t4-shared.yaml)
- [machineautoscaler-a10-private.yaml](../autoscaling/overlays/multi-autoscaling-pool/rhoaibu-cluster-dev/machineautoscaler-a10-private.yaml)
- [machineautoscaler-t4-private.yaml](../autoscaling/overlays/multi-autoscaling-pool/rhoaibu-cluster-dev/machineautoscaler-t4-private.yaml)

## Deployment Instructions

Currently, we do **not** deploy this configuration through **GitOps** due to conflicts between the **Machine Config API Operator** and the **ArgoCD controller**. Given the sensitivity of this setup, we deploy it manually using **Kustomization**:

```sh
kubectl apply -k components/configs/autoscaling/overlays/multi-autoscaling-pool/$CLUSTER
```