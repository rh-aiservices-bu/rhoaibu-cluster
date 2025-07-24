# 3scale Configuration Apply Script

This directory contains configuration files for 3scale API Management and a script to apply them in the correct order.

## Directory Structure

Each subdirectory represents a different model/service and contains:
- `backend.yaml` - Backend configuration
- `product.yaml` - Product configuration  
- `activedoc.yaml` - API documentation configuration
- `proxy-config-promote.yaml` - Proxy configuration for promotion
- `apidoc.json` - API documentation in JSON format

## Usage

### Apply All Configurations

```bash
./apply-all-configs.sh
```

This will apply all configuration files to the `3scale` namespace in the following order:
1. All `backend.yaml` files
2. All `product.yaml` files  
3. All `activedoc.yaml` files
4. All `proxy-config-promote.yaml` files

The script pauses between each stage to allow verification.

### Apply Specific File Type

To apply only one type of file without doing all stages:

```bash
./apply-all-configs.sh --type <file-type>
```

Valid file types are:
- `backend` - Apply only backend.yaml files
- `product` - Apply only product.yaml files  
- `activedoc` - Apply only activedoc.yaml files
- `proxy-config-promote` - Apply only proxy-config-promote.yaml files

Examples:
```bash
./apply-all-configs.sh --type activedoc         # Apply only activedoc files
./apply-all-configs.sh --type backend --dry-run # Dry run only backend files
```

### Dry Run Mode

To see what would be applied without making changes:

```bash
./apply-all-configs.sh --dry-run
```

This works with both all files and single file type modes.

### Help

```bash
./apply-all-configs.sh --help
```

## Script Behavior

- **Staged Application**: Files are applied in 4 stages to ensure dependencies are met
- **Interactive**: Pauses between stages (except in dry-run mode)
- **Error Handling**: Tracks failures and provides a summary
- **Safe**: Uses `set -euo pipefail` for strict error handling

## Requirements

- `oc` (OpenShift CLI) must be installed and configured
- You must be logged into the OpenShift cluster
- Access to the `3scale` namespace

## Example Output

```
=== Stage: Applying all backend files ===
✓ Successfully applied: backend.yaml from model-1
✓ Successfully applied: backend.yaml from model-2
...
Stage Summary - backend:
  Total files: 15
  Successful: 15
  Failed: 0

Press any key to continue to the next stage...
```

## Troubleshooting

If the script fails:
1. Check you're logged into OpenShift: `oc whoami`
2. Verify namespace access: `oc project 3scale`
3. Review individual file syntax: `oc apply -f <file> --dry-run=client`
4. Check the error messages in the script output

## Adding New Configurations

To add a new model/service:
1. Create a new subdirectory with the model name
2. Add all required YAML files following the existing pattern
3. Run the script to apply the new configurations