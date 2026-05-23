# Evidence Template

Use this file to collect screenshots and command outputs for the final
presentation or submission.

## Repository and Commit Evidence

Screenshot or paste output:

```bash
git log --oneline -5
git status --short
```

Expected evidence:

- Recent commits show GitOps changes.
- Working tree is clean.

## Kustomize Render Evidence

Screenshot or paste output:

```bash
kubectl kustomize manifests/overlays/prod
```

Expected evidence:

- `Namespace` named `gitops-lab`
- `Service` named `nginx-service`
- `Deployment` named `nginx-deployment`
- Deployment has two replicas.

## GitHub Actions Evidence

Screenshot:

- Workflow name: `Validate and Test Kubernetes Manifests`
- Latest run is green.

Expected evidence:

- Kustomize render succeeded.
- kubeconform validation succeeded.
- Kind deployment succeeded.
- NGINX smoke test succeeded.

## Argo CD Evidence

Screenshot:

- Argo CD application: `gitops-lab-nginx`
- Status: `Synced`
- Health: `Healthy`

Command output:

```bash
kubectl -n argocd get application gitops-lab-nginx
```

Expected evidence:

- Argo CD watches `manifests/overlays/prod`.
- Application is synced to `main`.

## Kubernetes Runtime Evidence

Screenshot or paste output:

```bash
kubectl -n gitops-lab get deployment,pods,svc
```

Expected evidence:

- Deployment has `2/2` ready replicas.
- Pods are running.
- Service exposes port `80` and NodePort `32000`.

## Application Access Evidence

Run:

```bash
kubectl -n gitops-lab port-forward svc/nginx-service 8080:80
```

Then open:

```text
http://localhost:8080
```

Expected evidence:

- Browser shows the default NGINX welcome page.

## Automated Sync Evidence

Change production replicas to `3` in:

```text
manifests/overlays/prod/kustomization.yaml
```

Commit and push:

```bash
git add manifests/overlays/prod/kustomization.yaml
git commit -m "scale production nginx to 3 replicas"
git push origin main
```

Expected evidence:

- Argo CD syncs the change.
- `kubectl -n gitops-lab get deployment nginx-deployment` shows 3 desired
  replicas.

## Rollback Evidence

Run:

```bash
git revert HEAD
git push origin main
```

Expected evidence:

- Argo CD syncs the revert.
- Deployment returns to 2 desired replicas.

## Self-Healing Evidence

Run:

```bash
kubectl -n gitops-lab scale deployment/nginx-deployment --replicas=1
```

Expected evidence:

- Argo CD detects drift.
- Argo CD restores the replica count from Git.
