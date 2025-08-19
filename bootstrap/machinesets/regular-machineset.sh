#!/bin/bash

### Define Instance Types
INSTANCE_TYPES=(
  "General Purpose Medium:m6i.4xlarge"
  "General Purpose Large:m6i.8xlarge"
  "General Purpose XLarge:m6i.12xlarge"
  "General Purpose XXLarge:m6i.16xlarge"
  "General Purpose M5 Medium:m5.4xlarge"
  "General Purpose M5 Large:m5.8xlarge"
  "General Purpose M5 XLarge:m5.12xlarge"
  "Compute Optimized Medium:c6i.4xlarge"
  "Compute Optimized Large:c6i.8xlarge"
  "Compute Optimized XLarge:c6i.12xlarge"
  "Memory Optimized Medium:r6i.4xlarge"
  "Memory Optimized Large:r6i.8xlarge"
  "Memory Optimized XLarge:r6i.12xlarge"
)

### Function to get instance type
get_instance_type() {
  local key="$1"
  # Remove parentheses and everything inside them from the key for comparison
  local clean_key="${key%% (*}"
  for instance in "${INSTANCE_TYPES[@]}"; do
    if [[ $instance == "$clean_key"* ]]; then
      echo "${instance#*:}"
      return 0
    fi
  done
  return 1
}

### Prompt User for Instance Type
echo "### Select the compute instance type:"
PS3='Please enter your choice: '
options=(
  "General Purpose Medium (m6i.4xlarge)"
  "General Purpose Large (m6i.8xlarge)"
  "General Purpose XLarge (m6i.12xlarge)"
  "General Purpose XXLarge (m6i.16xlarge)"
  "General Purpose M5 Medium (m5.4xlarge)"
  "General Purpose M5 Large (m5.8xlarge)"
  "General Purpose M5 XLarge (m5.12xlarge)"
  "Compute Optimized Medium (c6i.4xlarge)"
  "Compute Optimized Large (c6i.8xlarge)"
  "Compute Optimized XLarge (c6i.12xlarge)"
  "Memory Optimized Medium (r6i.4xlarge)"
  "Memory Optimized Large (r6i.8xlarge)"
  "Memory Optimized XLarge (r6i.12xlarge)"
)
select opt in "${options[@]}"
do
  INSTANCE_TYPE=$(get_instance_type "$opt")
  if [[ -n "$INSTANCE_TYPE" ]]; then
    COMPUTE_TYPE="$opt"
    break
  else
    echo "--- Invalid option $REPLY ---"
  fi
done

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
NEW_NAME="worker-compute-$INSTANCE_TYPE-$AZ$SPOT_SUFFIX"

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
    oc get -n openshift-machine-api "$MACHINESET" -o json | jq --arg INSTANCE_TYPE "$INSTANCE_TYPE" --arg NEW_NAME "$NEW_NAME" --arg SPOT_MARKET_OPTIONS "$SPOT_MARKET_OPTIONS" '
        (.metadata.name) |= $NEW_NAME |
        (.spec.selector.matchLabels["machine.openshift.io/cluster-api-machineset"]) |= $NEW_NAME |
        (.spec.template.metadata.labels["machine.openshift.io/cluster-api-machineset"]) |= $NEW_NAME |
        (.spec.template.spec.providerSpec.value.instanceType) |= $INSTANCE_TYPE |
        del(.spec.template.spec.metadata.labels["cluster-api/accelerator"]) |
        del(.spec.template.spec.taints) |
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