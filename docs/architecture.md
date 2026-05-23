# Architecture

This document describes the GitOps architecture used by the project.

## High-Level Flow

```text
Developer workstation
   |
   | 1. edit Kubernetes desired state
   | 2. git commit
   | 3. git push
   v
GitHub repository
   |
   | GitHub Actions
   | - render Kustomize production overlay
   | - validate Kubernetes schema
   | - deploy to temporary Kind cluster
   | - run NGINX smoke test
   v
main branch
   |
   | Argo CD watches manifests/overlays/prod
   v
Kubernetes cluster
   |
   | continuous reconciliation
   v
gitops-lab namespace
   |
   | Deployment + Service
   v
NGINX application
```

## Desired-State Layout

The Kubernetes resources are split into a base and overlays:

```text
manifests/
|-- kustomization.yaml
|-- base/
|   |-- kustomization.yaml
|   |-- nginx-app.yaml
|   `-- nginx-service.yaml
`-- overlays/
    |-- dev/
    |   |-- kustomization.yaml
    |   |-- namespace.yaml
    |   |-- deployment-labels.yaml
    |   |-- service-labels.yaml
    |   `-- nodeport-patch.yaml
    `-- prod/
        |-- kustomization.yaml
        |-- namespace.yaml
        |-- deployment-labels.yaml
        |-- service-labels.yaml
        `-- nodeport-patch.yaml
```

The base contains reusable application resources. The overlays represent
environment-specific desired state:

| Environment | Kustomize path | Namespace | Replicas | NodePort |
| --- | --- | --- | --- | --- |
| dev | `manifests/overlays/dev` | `gitops-lab-dev` | 1 | 32001 |
| prod | `manifests/overlays/prod` | `gitops-lab` | 2 | 32000 |

The root `manifests/kustomization.yaml` points to the production overlay so
existing commands such as `kubectl apply -k manifests` still deploy the
production desired state.

## GitOps Control Loop

Argo CD is configured by `gitops/argocd-application.yaml`.

It watches:

```text
repo: https://github.com/ichika0130/GitOps-Lab.git
branch: main
path: manifests/overlays/prod
```

When the Git desired state changes, Argo CD compares the rendered manifests with
the live cluster state. If there is a difference, it applies the changes until
the cluster matches Git again.

The application enables:

- automated sync
- prune
- self-heal
- namespace creation

## Change and Rollback Flow

Normal update:

```text
edit manifest -> commit -> push -> CI validates -> Argo CD syncs -> cluster updates
```

Rollback:

```text
git revert <bad-commit> -> push -> CI validates -> Argo CD syncs -> cluster returns to previous state
```

Self-healing:

```text
manual cluster drift -> Argo CD detects drift -> Argo CD restores Git-defined state
```

## Why This Is GitOps

This architecture follows the key GitOps principles:

- Git is the source of truth.
- The desired state is declarative.
- Changes are reviewed and audited through Git history.
- A controller pulls from Git and reconciles the cluster.
- Drift is corrected automatically.
