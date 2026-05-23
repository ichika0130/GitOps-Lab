# GitOps-Lab

University Cloud Computing Final Project.

This repository demonstrates a GitOps-based CI/CD workflow for deploying NGINX
to Kubernetes. The project uses Kubernetes manifests, Kustomize overlays,
GitHub Actions, Kind, Kubernetes server-side dry run, and Argo CD.

## Repository Structure

```text
.
|-- .github/workflows/validate-manifests.yml
|-- Makefile
|-- docs/
|   |-- architecture.md
|   |-- demo.md
|   |-- evidence-template.md
|   `-- report.md
|-- gitops/
|   `-- argocd-application.yaml
|-- manifests/
|   |-- kustomization.yaml
|   |-- base/
|   |   |-- kustomization.yaml
|   |   |-- nginx-app.yaml
|   |   `-- nginx-service.yaml
|   `-- overlays/
|       |-- dev/
|       `-- prod/
`-- README.md
```

## Environments

| Environment | Kustomize path | Namespace | Replicas | NodePort |
| --- | --- | --- | --- | --- |
| dev | `manifests/overlays/dev` | `gitops-lab-dev` | 1 | 32001 |
| prod | `manifests/overlays/prod` | `gitops-lab` | 2 | 32000 |

The root `manifests/kustomization.yaml` points to the production overlay for
backward-compatible commands such as `kubectl apply -k manifests`.

## Prerequisites

- A Kubernetes cluster, such as Minikube, Kind, or a managed cloud cluster
- `kubectl` configured for the target cluster
- Argo CD installed in the cluster for GitOps deployment
- `make` for the helper commands

## Local Kubernetes Deployment

Render production manifests:

```bash
make render-prod
```

Deploy production:

```bash
make deploy-prod
make rollout
make status
```

Access NGINX with port forwarding:

```bash
make port-forward
```

Then open:

```text
http://localhost:8080
```

You can also use direct `kubectl` commands:

```bash
kubectl apply -k manifests/overlays/prod
kubectl -n gitops-lab rollout status deployment/nginx-deployment
kubectl -n gitops-lab get deployment,pods,svc
```

## GitOps Deployment with Argo CD

Apply the Argo CD application:

```bash
kubectl apply -f gitops/argocd-application.yaml
```

Argo CD watches the `main` branch and synchronizes this path:

```text
manifests/overlays/prod
```

The Argo CD application enables automated sync, prune, self-heal, and namespace
creation.

If this repository is private, configure repository credentials in Argo CD
before applying the application manifest.

## Project Documentation

- [Project report](docs/report.md)
- [Architecture](docs/architecture.md)
- [Demo guide](docs/demo.md)
- [Evidence template](docs/evidence-template.md)

## Updating the Application

Use `manifests/base/` for shared application changes, such as the NGINX image,
ports, health checks, and resource requests.

Use `manifests/overlays/dev/` or `manifests/overlays/prod/` for environment
differences, such as namespace, replica count, and NodePort.

Common examples:

- Change `replicas.count` in `manifests/overlays/prod/kustomization.yaml` to
  scale production.
- Change the container image tag in `manifests/base/nginx-app.yaml` to roll out
  a new NGINX version.
- Change `nodePort` in `manifests/overlays/prod/nodeport-patch.yaml` if port
  `32000` is not available in the target cluster.

## Validation

The GitHub Actions workflow in `.github/workflows/validate-manifests.yml`
renders the production Kustomize overlay, validates the generated Kubernetes
objects with Kubernetes server-side dry run, deploys them to a temporary Kind
cluster, and runs an HTTP smoke test on every push and pull request.

Useful local commands:

```bash
make render-dev
make render-prod
make validate
```
