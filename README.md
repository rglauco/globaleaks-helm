## Setup

**using kind with the default storageClass "standard"**
1. `mkdir /data`
2. `kind create cluster --name mycluster --config kind.yml`
3. `kubectl apply -f pv.yml`
4. ```
   helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx && \
   helm repo update && \
   helm install ingress-nginx ingress-nginx/ingress-nginx \
   --namespace ingress-nginx --create-namespace \
   --set controller.admissionWebhooks.enabled=false \
   --set controller.hostPort.enabled=true \
   --set controller.service.type=NodePort
   ```
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
