KUSTOMIZE_PATH ?= manifests/overlays/prod
DEV_PATH ?= manifests/overlays/dev
PROD_PATH ?= manifests/overlays/prod
NAMESPACE ?= gitops-lab
DEPLOYMENT ?= nginx-deployment
SERVICE ?= nginx-service
PORT ?= 8080
RENDERED ?= /tmp/gitops-lab-rendered.yaml

.PHONY: render render-dev render-prod validate deploy deploy-dev deploy-prod rollout status port-forward smoke-test clean clean-dev clean-prod

render:
	kubectl kustomize $(KUSTOMIZE_PATH)

render-dev:
	kubectl kustomize $(DEV_PATH)

render-prod:
	kubectl kustomize $(PROD_PATH)

validate:
	kubectl kustomize $(KUSTOMIZE_PATH) > $(RENDERED)
	@if command -v kubeconform >/dev/null 2>&1; then \
		kubeconform -strict $(RENDERED); \
	else \
		echo "kubeconform is not installed; rendered manifests are available at $(RENDERED)"; \
	fi

deploy:
	kubectl apply -k $(KUSTOMIZE_PATH)

deploy-dev:
	kubectl apply -k $(DEV_PATH)

deploy-prod:
	kubectl apply -k $(PROD_PATH)

rollout:
	kubectl -n $(NAMESPACE) rollout status deployment/$(DEPLOYMENT) --timeout=120s

status:
	kubectl -n $(NAMESPACE) get deployment,pods,svc

port-forward:
	kubectl -n $(NAMESPACE) port-forward svc/$(SERVICE) $(PORT):80

smoke-test:
	curl -fsS http://127.0.0.1:$(PORT)/ | grep -qi "Welcome to nginx"

clean:
	kubectl delete -k $(KUSTOMIZE_PATH)

clean-dev:
	kubectl delete -k $(DEV_PATH)

clean-prod:
	kubectl delete -k $(PROD_PATH)
