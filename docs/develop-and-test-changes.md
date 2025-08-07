# Develop and Test Changes with GitOps

This document describes how to develop and test changes in the RHOAI BU Cluster using GitOps.

## Development and Testing Workflow

The repository supports a complete development lifecycle:

1. **Fork and Branch**: Developers create feature branches for infrastructure changes
2. **Local Testing**: Kustomize allows local validation before deployment
3. **Dev Environment**: Changes are tested in the development cluster first
4. **Production Promotion**: Validated changes are promoted to production via GitOps

## Prerequisites. 



- Access to the RHOAI BU Cluster repository
- `kubectl` configured for cluster access
- `kustomize` CLI tool
- `git` for version control

## Step-by-Step Development Process

### 1. Fork and Branch

Create a fork of the repository and work on feature branches:

```bash
# Fork the repository (via GitHub UI)
# Clone your fork
git clone https://github.com/YOUR_USERNAME/rhoaibu-cluster.git
cd rhoaibu-cluster

# Create a feature branch
git checkout -b feature/your-change-description
```

### 2. Local Testing

Validate your changes locally using Kustomize before deployment:

```bash
# Test component configurations
kustomize build components/configs/your-component

# Test cluster overlays
kustomize build clusters/overlays/development
kustomize build clusters/overlays/production

# Validate YAML syntax
kubectl --dry-run=client apply -f <(kustomize build clusters/overlays/development)
```

### 3. Dev Environment Testing

Deploy and test changes in the development cluster first:

```bash
# Apply changes to development cluster
kubectl apply -k clusters/overlays/development

# Monitor deployment status
kubectl get applications -n openshift-gitops
kubectl logs -f deployment/argocd-application-controller -n openshift-gitops

# Verify your changes
kubectl get pods -n your-namespace
kubectl describe <resource> <name>
```

### 4. Production Promotion

After successful testing in development, promote to production:

```bash
# Commit and push your tested changes
git add .
git commit -m "feat: describe your changes"
git push origin feature/your-change-description

# Create Pull Request (via GitHub UI)
# After PR approval and merge, changes are automatically deployed to production via GitOps
```

## Best Practices

### Configuration Management

- Use Kustomize overlays for environment-specific configurations
- Keep base configurations generic and environment-neutral
- Use patches for environment-specific modifications

### Testing Strategy

- Always test in development cluster before production
- Validate configurations locally with `kustomize build`
- Use `kubectl --dry-run` for syntax validation
- Monitor ArgoCD applications for sync status

### GitOps Workflow

- Make small, incremental changes
- Use descriptive commit messages
- Create feature branches for new functionality
- Review changes in pull requests before merging

## Monitoring Changes

- Monitor ArgoCD dashboard for application sync status
- Check cluster resources after deployments
- Verify application functionality in both environments
- Review logs for any deployment issues

This workflow ensures safe, tested changes are deployed through GitOps while maintaining cluster stability and compliance.