## Docker build

**Setup with kind using the default storageClass "standard"**
1. `mkdir /data`
2. `kind create cluster --name mycluster --config kind.yml`
3. `kubectl apply -f pv.yml`

## Deployment

Entity name = globaleaks1

**Deploy**

`helm install globaleaks1 -f globaleaks/values.yaml globaleaks/`

**Upgrade**

`helm upgrade globaleaks1 -f globaleaks/values.yaml globaleaks/`

**Undeploy**

`helm delete globaleaks1`

---------
Forked from https://github.com/pablovigo/globaleaks-helm
