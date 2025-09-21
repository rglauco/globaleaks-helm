## Setup

**using kind with the default storageClass "standard"**
1. `mkdir /data`
2. `kind create cluster --name mycluster --config kind.yml`
3. `kubectl apply -f pv.yml`

## Deployment

Entity name = globaleaks1

keep in mind: in `templates/ingress.yaml` you can find `spec.rules.host: {{ .Release.Name }}.example.com` as example to redirect traffic from external to the appropriate container using https

**Deploy**

`helm install globaleaks1 -f globaleaks/values.yaml globaleaks/`

**Upgrade**

`helm upgrade globaleaks1 -f globaleaks/values.yaml globaleaks/`

**Undeploy**

`helm delete globaleaks1`

---------
Forked from https://github.com/pablovigo/globaleaks-helm
