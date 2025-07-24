#!/bin/bash

# Script to apply all YAML files in subfolders to 3scale namespace in stages
# Usage: ./apply-all-configs.sh [--dry-run]

set -euo pipefail

NAMESPACE="3scale"
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DRY_RUN=false
FILE_TYPE=""

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --type)
            if [[ $# -lt 2 ]]; then
                echo "Error: --type requires a value"
                echo "Valid types: backend, product, activedoc, proxy-config-promote"
                exit 1
            fi
            FILE_TYPE="$2"
            case "$FILE_TYPE" in
                backend|product|activedoc|proxy-config-promote)
                    ;;
                *)
                    echo "Error: Invalid file type '$FILE_TYPE'"
                    echo "Valid types: backend, product, activedoc, proxy-config-promote"
                    exit 1
                    ;;
            esac
            shift 2
            ;;
        -h|--help)
            echo "Usage: $0 [--dry-run] [--type <file-type>]"
            echo "  --dry-run           Show what would be applied without actually applying"
            echo "  --type <file-type>  Apply only specific file type"
            echo "                      Valid types: backend, product, activedoc, proxy-config-promote"
            echo "  -h, --help          Show this help message"
            echo ""
            echo "Examples:"
            echo "  $0                          # Apply all files in order"
            echo "  $0 --dry-run                # Dry run all files"
            echo "  $0 --type activedoc         # Apply only activedoc.yaml files"
            echo "  $0 --type backend --dry-run # Dry run only backend.yaml files"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

if [ "$DRY_RUN" = true ]; then
    echo "DRY RUN MODE - No changes will be applied"
fi
echo "Namespace: $NAMESPACE"
echo "Base directory: $BASE_DIR"
echo "========================================"

# Function to apply files of a specific type
apply_files() {
    local file_pattern="$1"
    local file_type="$2"
    local count=0
    local success=0
    local failed=0
    
    echo
    echo "=== Stage: Applying all $file_type files ==="
    echo
    
    for yaml_file in $BASE_DIR/*/$file_pattern; do
        if [ -f "$yaml_file" ]; then
            if [ "$DRY_RUN" = true ]; then
                echo "[DRY RUN] Would apply: $yaml_file"
                success=$((success + 1))
                echo "✓ Would apply: $(basename "$yaml_file") from $(basename "$(dirname "$yaml_file")")"
            else
                echo "Applying: $yaml_file"
                
                if oc apply -f "$yaml_file" -n "$NAMESPACE"; then
                    success=$((success + 1))
                    echo "✓ Successfully applied: $(basename "$yaml_file") from $(basename "$(dirname "$yaml_file")")"
                else
                    failed=$((failed + 1))
                    echo "✗ Failed to apply: $(basename "$yaml_file") from $(basename "$(dirname "$yaml_file")")"
                fi
            fi
            
            count=$((count + 1))
            echo "----------------------------------------"
        fi
    done
    
    echo
    echo "Stage Summary - $file_type:"
    echo "  Total files: $count"
    if [ "$DRY_RUN" = true ]; then
        echo "  Would apply: $success"
    else
        echo "  Successful: $success"
        echo "  Failed: $failed"
    fi
    
    return $failed
}

# Function to pause and wait for user input
pause_for_user() {
    if [ "$DRY_RUN" = true ]; then
        echo
        echo "========================================"
        echo "[DRY RUN] Skipping pause - moving to next stage"
        echo "========================================"
        return 0
    else
        echo
        echo "========================================"
        echo "Press any key to continue to the next stage..."
        echo "========================================"
        read -n 1 -s -r
        echo
    fi
}

# Overall counters
total_failed=0

# Apply specific file type or all files in order
if [ -n "$FILE_TYPE" ]; then
    echo "Single file type mode: applying only $FILE_TYPE files"
    echo "========================================"
    case "$FILE_TYPE" in
        backend)
            apply_files "backend.yaml" "backend"
            total_failed=$((total_failed + $?))
            ;;
        product)
            apply_files "product.yaml" "product"
            total_failed=$((total_failed + $?))
            ;;
        activedoc)
            apply_files "activedoc.yaml" "activedoc"
            total_failed=$((total_failed + $?))
            ;;
        proxy-config-promote)
            apply_files "proxy-config-promote.yaml" "proxy-config-promote"
            total_failed=$((total_failed + $?))
            ;;
    esac
else
    # Stage 1: Apply all backend.yaml files
    apply_files "backend.yaml" "backend"
    total_failed=$((total_failed + $?))

    pause_for_user

    # Stage 2: Apply all product.yaml files
    apply_files "product.yaml" "product"
    total_failed=$((total_failed + $?))

    pause_for_user

    # Stage 3: Apply all activedoc.yaml files
    apply_files "activedoc.yaml" "activedoc"
    total_failed=$((total_failed + $?))

    pause_for_user

    # Stage 4: Apply all proxy-config-promote.yaml files
    apply_files "proxy-config-promote.yaml" "proxy-config-promote"
    total_failed=$((total_failed + $?))
fi

# Final summary
echo
echo "========================================"
echo "=== FINAL SUMMARY ==="
echo "========================================"

if [ "$DRY_RUN" = true ]; then
    echo "DRY RUN COMPLETED - No changes were made"
    echo "All stages simulated successfully."
    echo "Run without --dry-run to actually apply the configurations."
    exit 0
else
    echo "All stages completed."
    
    if [ $total_failed -gt 0 ]; then
        echo "WARNING: $total_failed total files failed to apply across all stages."
        echo "Please check the errors above."
        exit 1
    else
        echo "SUCCESS: All configurations applied successfully!"
        exit 0
    fi
fi