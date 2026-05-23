# Project Report: Cloud-Native CI/CD Pipelines with GitOps

## Selected Project Topic

This project implements topic 6 from the project ideas list:

Cloud-Native CI/CD Pipelines with GitOps.

The goal is to show how a cloud-native application can be deployed by using a
Git repository as the source of truth. The implementation uses Kubernetes,
Kustomize, GitHub Actions, Kind, kubeconform, and Argo CD.

## Project Objectives

- Define application and infrastructure state declaratively.
- Validate Kubernetes manifests before deployment.
- Test deployment in a temporary Kubernetes cluster.
- Deploy the production environment automatically through Argo CD.
- Demonstrate rollback through Git history.
- Compare GitOps with a traditional CI/CD deployment model.
- Document testing, observability, and secret-management considerations.

## Application Scope

The sample application is an NGINX web server deployed to Kubernetes. It is a
small application by design, so the project can focus on the GitOps pipeline and
deployment process rather than application code.

The production deployment creates:

- `Namespace` named `gitops-lab`
- `Deployment` named `nginx-deployment`
- `Service` named `nginx-service`

The production deployment runs two NGINX replicas and includes readiness probes,
liveness probes, and resource requests and limits.

## Architecture

```text
Developer
   |
   | git commit / git push
   v
GitHub Repository
   |
   | GitHub Actions validates and tests prod overlay
   v
main branch as desired state
   |
   | Argo CD watches manifests/overlays/prod
   v
Kubernetes Cluster
   |
   | reconciles live state to desired state
   v
NGINX application in gitops-lab namespace
```

More architecture detail is available in `docs/architecture.md`.

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

## Declarative Infrastructure

The desired Kubernetes state is stored in `manifests/`. Kustomize separates
shared application resources from environment-specific configuration.

| Environment | Kustomize path | Namespace | Replicas | NodePort |
| --- | --- | --- | --- | --- |
| dev | `manifests/overlays/dev` | `gitops-lab-dev` | 1 | 32001 |
| prod | `manifests/overlays/prod` | `gitops-lab` | 2 | 32000 |

The base contains reusable resources:

- `nginx-app.yaml`
- `nginx-service.yaml`

The overlays define environment-specific namespace, labels, replica count, and
NodePort.

Render or deploy production:

```bash
kubectl kustomize manifests/overlays/prod
kubectl apply -k manifests/overlays/prod
```

The root `manifests/kustomization.yaml` points to the production overlay, so
this command also deploys production:

```bash
kubectl apply -k manifests
```

## GitOps Deployment

The Argo CD application is defined in `gitops/argocd-application.yaml`.

Important configuration choices:

- `repoURL` points to this GitHub repository.
- `targetRevision` is `main`.
- `path` is `manifests/overlays/prod`.
- `automated.prune` removes resources that are deleted from Git.
- `automated.selfHeal` restores resources when live cluster state drifts from
  Git.
- `CreateNamespace=true` allows Argo CD to create the target namespace.

With this setup, Argo CD continuously compares the Kubernetes cluster against
the desired state in Git and reconciles differences automatically.

## CI Pipeline

GitHub Actions runs on pushes to `main` and on pull requests. The workflow
performs these checks:

1. Render the production Kustomize overlay.
2. Validate the rendered Kubernetes objects with kubeconform.
3. Create a temporary Kind Kubernetes cluster.
4. Deploy the production overlay.
5. Wait for the NGINX deployment rollout.
6. Run an HTTP smoke test against the NGINX service.

This gives feedback before Argo CD applies a change to a real cluster.

## Testing Strategy

The project uses the following tests:

- Kustomize rendering for the desired state.
- Kubernetes schema validation through kubeconform.
- Deployment test in a temporary Kubernetes cluster.
- Rollout test with `kubectl rollout status`.
- HTTP smoke test that checks the NGINX welcome page.

These tests cover invalid YAML, invalid Kubernetes objects, failed scheduling,
failed rollout, and a service that does not respond.

## Rollback Strategy

The preferred rollback method is Git-based rollback:

```bash
git revert <bad-commit>
git push origin main
```

After the revert is pushed, GitHub Actions validates the reverted desired state.
Argo CD then detects the updated state and reconciles the cluster back to the
previous working configuration.

This keeps Git as the source of truth. It is better than manually editing the
live cluster because the rollback is reviewed, recorded, and repeatable.

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
- The manifest structure supports reusable base resources and environment
  overlays.
- CI validates and tests each change.
- Argo CD automates production deployment from Git to Kubernetes.
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

Future improvements could include canary deployments, Helm support, Prometheus
metrics, and a sealed-secret example.
