#!/bin/bash

### Define Instance Types
INSTANCE_TYPES=(
  "Tesla T4 Single GPU:g4dn.2xlarge"
  "Tesla T4 Multi GPU:g4dn.12xlarge"
  "A10G Single GPU:g5.2xlarge"
  "A10G Multi GPU x4:g5.12xlarge"
  "A10G Multi GPU x8:g5.48xlarge"
  "A100:p4d.24xlarge"
  "H100:p5.48xlarge"
  "DL1:dl1.24xlarge"
  "L40 Single GPU:g6.2xlarge"
  "L40 Multi GPU x4:g6.12xlarge"
  "L40 Multi GPU x8:g6.48xlarge"
  "L40S Single GPU:g6e.2xlarge"
  "L40S Multi GPU x4:g6e.12xlarge"
  "L40S Multi GPU x8:g6e.48xlarge"
)

### Function to get instance type
get_instance_type() {
  local key="$1"
  for instance in "${INSTANCE_TYPES[@]}"; do
    if [[ $instance == "$key"* ]]; then
      echo "${instance#*:}"
      return 0
    fi
  done
  return 1
}

### Prompt User for GPU Instance Type
echo "### Select the GPU instance type:"
PS3='Please enter your choice: '
options=(
  "Tesla T4 Single GPU"
  "Tesla T4 Multi GPU"
  "A10G Single GPU"
  "A10G Multi GPU x4"
  "A10G Multi GPU x8"
  "A100"
  "H100"
  "DL1"
  "L40 Single GPU"
  "L40 Multi GPU x4"
  "L40 Multi GPU x8"
  "L40S Single GPU"
  "L40S Multi GPU x4"
  "L40S Multi GPU x8"
)
select opt in "${options[@]}"
do
  INSTANCE_TYPE=$(get_instance_type "$opt")
  if [[ -n "$INSTANCE_TYPE" ]]; then
    GPU_TYPE="$opt"
    break
  else
    echo "--- Invalid option $REPLY ---"
  fi
done

### Prompt User for GPU Type Mode (SHARED or PRIVATE)
read -p "### Is this GPU internal (PRIVATE) or external (SHARED)? [default: SHARED] (Enter p for PRIVATE, anything else for SHARED): " GPU_MODE

if [[ "$GPU_MODE" == "p" || "$GPU_MODE" == "P" ]]; then
  GPU_ACCESS_TYPE="PRIVATE"
  NAME_SUFFIX="-private"
else
  GPU_ACCESS_TYPE="SHARED"
  NAME_SUFFIX=""
fi

### Prompt User for Region
read -p "### Enter the AWS region (default: us-west-2): " REGION
REGION=${REGION:-us-west-2}

### Prompt User for Availability Zone
echo "### Select the availability zone (az1, az2, az3):"
PS3='Please enter your choice: '
az_options=("az1" "az2" "az3")
select az_opt in "${az_options[@]}"
do
  case $az_opt in
    "az1") AZ="${REGION}a" ; break ;;
    "az2") AZ="${REGION}b" ; break ;;
    "az3") AZ="${REGION}c" ; break ;;
    *) echo "--- Invalid option $REPLY ---" ;;
  esac
done

# Prompt User to Enable Spot Instances
read -p "### Do you want to enable spot instances? (y/n): " enable_spot

if [[ "$enable_spot" == "y" || "$enable_spot" == "Y" ]]; then
  SPOT_MARKET_OPTIONS='"spotMarketOptions": {}'
  SPOT_SUFFIX="-spot"
else
  SPOT_MARKET_OPTIONS=""
  SPOT_SUFFIX=""
fi

# Assign new name for the machineset
NEW_NAME="worker-gpu-$INSTANCE_TYPE$NAME_SUFFIX-$AZ$SPOT_SUFFIX"

# Define accelerator label based on GPU type and SHARED/PRIVATE selection
case $GPU_TYPE in
  "Tesla T4 Single GPU"|"Tesla T4 Multi GPU")
    ACCELERATOR_LABEL="Tesla-T4-$GPU_ACCESS_TYPE"
    ;;
  "A10G Single GPU"|"A10G Multi GPU x4"|"A10G Multi GPU x8")
    ACCELERATOR_LABEL="NVIDIA-A10G-$GPU_ACCESS_TYPE"
    ;;
  "A100")
    ACCELERATOR_LABEL="NVIDIA-A100-$GPU_ACCESS_TYPE"
    ;;
  "H100")
    ACCELERATOR_LABEL="NVIDIA-H100-$GPU_ACCESS_TYPE"
    ;;
  "L40 Single GPU"|"L40 Multi GPU x4"|"L40 Multi GPU x8")
    ACCELERATOR_LABEL="NVIDIA-L40-$GPU_ACCESS_TYPE"
    ;;
  "L40S Single GPU")
    ACCELERATOR_LABEL="NVIDIA-L40S-$GPU_ACCESS_TYPE"
    ;;
  "L40S Multi GPU x4"|"L40S Multi GPU x8")
    ACCELERATOR_LABEL="NVIDIA-L40S-MULTI-$GPU_ACCESS_TYPE"
    ;;
  *)
    ACCELERATOR_LABEL=""
    ;;
esac

# Check if the machineset already exists
EXISTING_MACHINESET=$(oc get -n openshift-machine-api machinesets -o name | grep "$NEW_NAME")

if [ -n "$EXISTING_MACHINESET" ]; then
  echo "### Machineset $NEW_NAME already exists. Scaling to 1."
  oc scale --replicas=1 -n openshift-machine-api "$EXISTING_MACHINESET"
  echo "--- Machineset $NEW_NAME scaled to 1."
else
  echo "### Creating new machineset $NEW_NAME."
  oc get -n openshift-machine-api machinesets -o name | grep -v ocs | while read -r MACHINESET
  do
    oc get -n openshift-machine-api "$MACHINESET" -o json | jq --arg INSTANCE_TYPE "$INSTANCE_TYPE" --arg NEW_NAME "$NEW_NAME" --arg ACCELERATOR_LABEL "$ACCELERATOR_LABEL" --arg SPOT_MARKET_OPTIONS "$SPOT_MARKET_OPTIONS" '
        (.metadata.name) |= $NEW_NAME |
        (.spec.selector.matchLabels["machine.openshift.io/cluster-api-machineset"]) |= $NEW_NAME |
        (.spec.template.metadata.labels["machine.openshift.io/cluster-api-machineset"]) |= $NEW_NAME |
        (.spec.template.spec.providerSpec.value.instanceType) |= $INSTANCE_TYPE |
        (.spec.template.spec.metadata.labels["cluster-api/accelerator"]) |= $ACCELERATOR_LABEL |
        (.spec.template.spec.taints) |= [{ "effect": "NoSchedule", "key": "nvidia.com/gpu", "value": $ACCELERATOR_LABEL }] |
        if $SPOT_MARKET_OPTIONS != "" then
          .spec.template.spec.providerSpec.value.spotMarketOptions |= {}
        else
          del(.spec.template.spec.providerSpec.value.spotMarketOptions)
        end
    ' | oc create -f -
    break
  done
  echo "--- New machineset $NEW_NAME created."
fi
