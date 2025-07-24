#!/bin/bash

### Define Instance Types
declare -A INSTANCE_TYPES
INSTANCE_TYPES=(
  ["m5.metal"]="m5.metal"
  ["m5d.metal"]="m5d.metal"
  ["m5n.metal"]="m5n.metal"
  ["m5zn.metal"]="m5zn.metal"
  ["c5.metal"]="c5.metal"
  ["c5n.metal"]="c5n.metal"
  ["i3.metal"]="i3.metal"
  ["i3en.metal"]="i3en.metal"
  ["u-6tb1.metal"]="u-6tb1.metal"
)

### Prompt User for Metal Instance Type
echo "### Select the metal instance type:"
PS3='Please enter your choice: '
options=(
  "m5.metal"
  "m5d.metal"
  "m5n.metal"
  "m5zn.metal"
  "c5.metal"
  "c5n.metal"
  "i3.metal"
  "i3en.metal"
  "u-6tb1.metal"
)
select opt in "${options[@]}"
do
  case $opt in
    "m5.metal"|"m5d.metal"|"m5n.metal"|"m5zn.metal"|"c5.metal"|"c5n.metal"|"i3.metal"|"i3en.metal"|"u-6tb1.metal")
      INSTANCE_TYPE=${INSTANCE_TYPES["$opt"]}
      break
      ;;
    *) echo "--- Invalid option $REPLY ---";;
  esac
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
    "az1")
      AZ="${REGION}a"
      break
      ;;
    "az2")
      AZ="${REGION}b"
      break
      ;;
    "az3")
      AZ="${REGION}c"
      break
      ;;
    *) echo "--- Invalid option $REPLY ---";;
  esac
done

# Assign new name for the machineset
NEW_NAME="worker-metal-$INSTANCE_TYPE-$AZ"

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
    oc get -n openshift-machine-api "$MACHINESET" -o json | jq '
        del(.metadata.uid, .metadata.managedFields, .metadata.selfLink, .metadata.resourceVersion, .metadata.creationTimestamp, .metadata.generation, .status) |
        (.metadata.name, .spec.selector.matchLabels["machine.openshift.io/cluster-api-machineset"], .spec.template.metadata.labels["machine.openshift.io/cluster-api-machineset"]) |= sub("worker";"worker-metal") |
        (.spec.template.spec.providerSpec.value.instanceType) |= "'"$INSTANCE_TYPE"'" |
        (.metadata.name) |= "'"$NEW_NAME"'" |
        (.spec.template.metadata.labels["machine.openshift.io/cluster-api-machineset"]) |= "'"$NEW_NAME"'" |
        (.spec.selector.matchLabels["machine.openshift.io/cluster-api-machineset"]) |= "'"$NEW_NAME"'" |
        (.spec.template.spec.metadata.labels["devices.kubevirt.io/kvm"]) |= ""' | oc apply -f -
    break
  done
  echo "--- New machineset $NEW_NAME created."
fi
