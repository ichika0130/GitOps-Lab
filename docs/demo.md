# Demo Guide

This guide provides a reproducible demo flow for the GitOps final project.

## 1. Preflight

Confirm the repository is clean and Kubernetes manifests render correctly:

```bash
git status --short
make render-prod
```

Expected result:

- `git status --short` prints no local changes.
- `make render-prod` renders a `Namespace`, `Service`, and `Deployment`.

You can also render directly:

```bash
kubectl kustomize manifests/overlays/prod
```

## 2. Validate Through GitHub Actions

Push a change or open a pull request.

The workflow in `.github/workflows/validate-manifests.yml` should:

1. Render the production overlay with Kustomize.
2. Validate the rendered objects with Kubernetes server-side dry run.
3. Create a temporary Kind Kubernetes cluster.
4. Deploy the production overlay.
5. Wait for the deployment rollout.
6. Run an HTTP smoke test against the NGINX service.

This proves the manifests are not only valid YAML, but also deployable.

## 3. Deploy Manually for Local Verification

Use this path if you want to test without Argo CD:

```bash
make deploy-prod
make rollout
make status
```

Equivalent direct commands:

```bash
kubectl apply -k manifests/overlays/prod
kubectl -n gitops-lab rollout status deployment/nginx-deployment
kubectl -n gitops-lab get deployment,pods,svc
```

Access the service:

```bash
make port-forward
```

Or:

```bash
kubectl -n gitops-lab port-forward svc/nginx-service 8080:80
```

Open:

```text
http://localhost:8080
```

The page should show the default NGINX welcome page.

## 4. Deploy with Argo CD

Argo CD must already be installed in the cluster.

Apply the GitOps application:

```bash
kubectl apply -f gitops/argocd-application.yaml
```

Check the Argo CD application:

```bash
kubectl -n argocd get application gitops-lab-nginx
kubectl -n gitops-lab get deployment,pods,svc
```

Expected result:

- Argo CD creates or updates resources from `manifests/overlays/prod`.
- The `gitops-lab` namespace contains the NGINX deployment and service.
- The deployment has two ready replicas.

## 5. Demonstrate Automated Sync

Change the production replica count in
`manifests/overlays/prod/kustomization.yaml`:

```yaml
replicas:
  - name: nginx-deployment
    count: 3
```

Commit and push:

```bash
git add manifests/overlays/prod/kustomization.yaml
git commit -m "scale production nginx to 3 replicas"
git push origin main
```

After Argo CD syncs, verify the live state:

```bash
kubectl -n gitops-lab get deployment nginx-deployment
```

Expected result:

- Desired replicas change to `3`.
- Three pods become ready.

## 6. Demonstrate Rollback

Revert the previous change:

```bash
git revert HEAD
git push origin main
```

After Argo CD syncs again, verify the rollback:

```bash
kubectl -n gitops-lab get deployment nginx-deployment
```

Expected result:

- Desired replicas return to `2`.
- The cluster state matches Git again.

## 7. Demonstrate Self-Healing

Manually change the live deployment:

```bash
kubectl -n gitops-lab scale deployment/nginx-deployment --replicas=1
kubectl -n gitops-lab get deployment nginx-deployment
```

Because Argo CD has `selfHeal: true`, it should restore the deployment to the
replica count stored in Git.

Verify:

```bash
kubectl -n gitops-lab get deployment nginx-deployment
```

Expected result:

- The live deployment returns to the Git-defined replica count.

## 8. Evidence Checklist for Presentation

Capture these screenshots or terminal outputs for the final presentation:

- GitHub Actions workflow passing.
- `kubectl kustomize manifests/overlays/prod` output.
- Argo CD application showing Synced and Healthy.
- `kubectl -n gitops-lab get deployment,pods,svc`.
- Browser showing the NGINX welcome page.
- Replica count change after a Git commit.
- Rollback after `git revert`.
- Self-healing after a manual live-cluster change.

Use `docs/evidence-template.md` to collect the final evidence.
