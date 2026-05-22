# GitOps-Lab

University Cloud Computing Final Project.

This repository demonstrates a simple GitOps workflow for deploying a
two-replica NGINX application to Kubernetes. The Kubernetes resources live in
`manifests/`, and an optional Argo CD `Application` is provided in `gitops/`.

## Repository Structure

```text
.
|-- .github/workflows/validate-manifests.yml
|-- gitops/
|   `-- argocd-application.yaml
|-- manifests/
|   |-- kustomization.yaml
|   |-- namespace.yaml
|   |-- nginx-app.yaml
|   `-- nginx-service.yaml
`-- README.md
```

## Prerequisites

- A Kubernetes cluster, such as Minikube, Kind, or a managed cloud cluster
- `kubectl` configured for the target cluster
- Argo CD installed in the cluster if you want to use the GitOps workflow

## Local Kubernetes Deployment

Render the manifests with Kustomize:

```bash
kubectl kustomize manifests
```

Deploy the application directly with `kubectl`:

```bash
kubectl apply -k manifests
```

Check the deployment status:

```bash
kubectl -n gitops-lab get deployment,pods,svc
```

Access the NGINX service with port forwarding:

```bash
kubectl -n gitops-lab port-forward svc/nginx-service 8080:80
```

Then open:

```text
http://localhost:8080
```

If your cluster supports NodePort access, you can also use:

```text
http://<node-ip>:32000
```

## GitOps Deployment with Argo CD

Apply the Argo CD application:

```bash
kubectl apply -f gitops/argocd-application.yaml
```

Argo CD will watch the `main` branch and synchronize the resources from the
`manifests/` directory into the `gitops-lab` namespace.

If this repository is private, configure repository credentials in Argo CD
before applying the application manifest.

## Updating the Application

To change the desired state, edit the files in `manifests/`, commit the change,
and push it to the `main` branch. Argo CD will detect the change and reconcile
the cluster automatically.

Common examples:

- Change `spec.replicas` in `manifests/nginx-app.yaml` to scale the deployment.
- Change the container image tag in `manifests/nginx-app.yaml` to roll out a new
  NGINX version.
- Change `nodePort` in `manifests/nginx-service.yaml` if port `32000` is not
  available in the target cluster.

## Validation

The GitHub Actions workflow in `.github/workflows/validate-manifests.yml`
renders the Kustomize manifests and validates the generated Kubernetes objects
on every push and pull request.
