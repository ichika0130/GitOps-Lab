# Project Report: Cloud-Native CI/CD Pipelines with GitOps

## Selected Project Topic

This project implements topic 6 from the project ideas list:

Cloud-Native CI/CD Pipelines with GitOps.

The goal is to show how a cloud-native application can be deployed by using a
Git repository as the source of truth. The implementation uses Kubernetes,
Kustomize, GitHub Actions, and Argo CD.

## Project Objectives

- Define the application and infrastructure state declaratively.
- Validate Kubernetes manifests before deployment.
- Deploy the application automatically through a GitOps controller.
- Demonstrate rollback through Git history.
- Compare GitOps with a traditional CI/CD deployment model.
- Document testing, observability, and secret-management considerations.

## Application Scope

The sample application is an NGINX web server deployed to Kubernetes. It is a
small application by design, so the project can focus on the GitOps pipeline and
the deployment process rather than application code.

The deployed Kubernetes resources are:

- `Namespace` named `gitops-lab`
- `Deployment` named `nginx-deployment`
- `Service` named `nginx-service`

The deployment runs two NGINX replicas and includes readiness probes, liveness
probes, and resource requests and limits.

## Architecture

```text
Developer
   |
   | git commit / git push
   v
GitHub Repository
   |
   | GitHub Actions validates and tests manifests
   v
main branch as desired state
   |
   | Argo CD watches repository path: manifests/
   v
Kubernetes Cluster
   |
   | reconciles live state to desired state
   v
NGINX application in gitops-lab namespace
```

## Repository Structure

```text
.
|-- .github/workflows/validate-manifests.yml
|-- docs/
|   |-- demo.md
|   `-- report.md
|-- gitops/
|   `-- argocd-application.yaml
|-- manifests/
|   |-- kustomization.yaml
|   |-- namespace.yaml
|   |-- nginx-app.yaml
|   `-- nginx-service.yaml
`-- README.md
```

## Declarative Infrastructure

The desired Kubernetes state is stored in `manifests/`. Kustomize is used as the
entry point, so the whole application can be rendered or deployed with one
command:

```bash
kubectl kustomize manifests
kubectl apply -k manifests
```

This keeps the infrastructure declarative. The cluster should match the files in
Git, and changes are made by editing YAML files rather than manually changing
live Kubernetes objects.

## GitOps Deployment

The Argo CD application is defined in `gitops/argocd-application.yaml`.

Important configuration choices:

- `repoURL` points to this GitHub repository.
- `targetRevision` is `main`.
- `path` is `manifests`.
- `automated.prune` removes resources that are deleted from Git.
- `automated.selfHeal` restores resources when live cluster state drifts from
  Git.
- `CreateNamespace=true` allows Argo CD to create the target namespace.

With this setup, Argo CD continuously compares the Kubernetes cluster against
the desired state in Git and reconciles differences automatically.

## CI Pipeline

GitHub Actions runs on pushes to `main` and on pull requests. The workflow
performs three levels of validation:

1. Render the Kustomize configuration.
2. Validate the rendered Kubernetes objects with kubeconform.
3. Deploy the manifests to a temporary Kind cluster and run a smoke test against
   the NGINX service.

This gives faster feedback before Argo CD applies a change to a real cluster.

## Testing Strategy

The project uses the following tests:

- YAML parsing through Kustomize rendering.
- Kubernetes schema validation through kubeconform.
- Deployment test in a temporary Kubernetes cluster.
- Rollout test with `kubectl rollout status`.
- HTTP smoke test that checks the NGINX welcome page.

These tests cover the most important failure modes for this project: invalid
YAML, invalid Kubernetes objects, failed scheduling, failed rollout, and a
service that does not respond.

## Rollback Strategy

The preferred rollback method is Git-based rollback:

```bash
git revert <bad-commit>
git push origin main
```

After the revert is pushed, Argo CD detects the updated desired state and
reconciles the cluster back to the previous working configuration.

This approach keeps Git as the source of truth. It is better than manually
editing the live cluster because the rollback is reviewed, recorded, and
repeatable.

Argo CD also has application history and rollback features, but using Git revert
is the clearest method for this project because it preserves the GitOps model.

## Secrets Management

The current NGINX application does not require secrets. If the application were
extended to include credentials, secrets should not be committed as plain text.

Recommended GitOps-compatible options include:

- Sealed Secrets
- External Secrets Operator
- SOPS-encrypted Kubernetes secrets
- Cloud provider secret managers integrated with Kubernetes

This project keeps secrets out of scope because the sample application does not
need them.

## Observability

This project includes basic Kubernetes observability:

- Readiness probe for traffic readiness.
- Liveness probe for container health.
- Argo CD application health and sync status.
- `kubectl get`, `kubectl describe`, and `kubectl logs` for operational checks.

For a larger production deployment, this could be extended with Prometheus,
Grafana, and alerting on deployment health, pod restarts, and service latency.

## GitOps vs Traditional CI/CD

| Area | Traditional CI/CD | GitOps |
| --- | --- | --- |
| Source of truth | CI pipeline or deployment scripts | Git repository |
| Deployment trigger | Pipeline pushes changes to cluster | Controller pulls desired state from Git |
| Cluster credentials | Usually stored in CI system | Usually stored only in the cluster controller |
| Drift handling | Often manual or periodic | Continuous reconciliation |
| Rollback | Re-run an old pipeline or script | Revert Git commit |
| Audit trail | Split between CI logs and Git | Git history is central |
| Reliability | Depends on pipeline execution | Controller keeps reconciling until state matches Git |

GitOps improves reliability because the cluster is continuously reconciled to
the desired state. It also improves auditability because changes are represented
as Git commits.

## Evaluation

The project satisfies the core requirements of a GitOps-based CI/CD pipeline:

- The application is declared in Git.
- CI validates and tests each change.
- Argo CD automates deployment from Git to Kubernetes.
- Rollback is performed through Git history.
- The workflow reduces manual deployment steps and provides a clear audit trail.

Deployment frequency can improve because every accepted change to `main` becomes
a deployable desired-state update. Reliability improves because CI catches
manifest problems early and Argo CD continuously corrects drift.

## Limitations and Future Work

- The application is intentionally simple and does not include business logic.
- The project documents observability but does not deploy Prometheus or Grafana.
- The project documents secret-management options but does not need live
  secrets.
- Final presentation evidence should include screenshots or command output from
  a real Argo CD sync.

Future improvements could include canary deployments, Helm support,
environment-specific overlays, Prometheus metrics, and a sealed-secret example.
