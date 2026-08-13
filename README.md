## Setup

**using kind with the default storageClass "standard"**

kind ships with a default dynamic StorageClass named `standard` (backed by `rancher.io/local-path`), which is what `values.yaml` targets — no PV/StorageClass needs to be created manually.

1. `kind create cluster --name mycluster --config kind.yml`
2. ```
   helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx && \
   helm repo update && \
   helm install ingress-nginx ingress-nginx/ingress-nginx \
   --namespace ingress-nginx --create-namespace \
   --set controller.admissionWebhooks.enabled=false \
   --set controller.hostPort.enabled=true \
   --set controller.service.type=NodePort
   ```
3. `kubectl apply -f ingressClass.yml`

**End-to-end test**

`./e2e-test.sh` spins up a throwaway kind cluster, installs ingress-nginx, deploys two chart releases behind two different hostnames, checks that both come up and are reachable, then tears the cluster down. It expects `azienda1.example.com` and `globaleaks.example.com` to resolve to `127.0.0.1` (e.g. via `/etc/hosts`). `kind.yml` maps the ingress to host ports `18080`/`18443` (instead of `80`/`443`) to avoid clashing with other services already running on the host — so after setup you can also browse to `https://globaleaks.example.com:18443/` manually. Set `KEEP_CLUSTER=true ./e2e-test.sh` to leave the cluster running afterwards for manual poking.

The same script runs in CI on every push/PR to `main` (see `.github/workflows/e2e-test.yml`), and can also be triggered manually from the Actions tab.
## Deployment

Entity name = globaleaks1

The ingress defaults to host `{{ .Release.Name }}.example.com`; override it with `--set ingress.host=your.domain.tld` or disable the ingress entirely with `--set ingress.enabled=false`.

The ingress terminates TLS using a secret named by `ingress.tlsSecretName` (default `globaleaks-tls`), which must already exist in the target namespace before install, this chart does not create it. Create it from an existing cert/key pair with:

```
kubectl create secret tls globaleaks-tls --cert=globaleaks.crt --key=globaleaks.key
```

**Deploy**

`helm install globaleaks1 -f globaleaks/values.yaml globaleaks/`

**Upgrade**

`helm upgrade globaleaks1 -f globaleaks/values.yaml globaleaks/`

**Undeploy**

`helm delete globaleaks1`

---------
Forked from https://github.com/pablovigo/globaleaks-helm
