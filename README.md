
## Deployment

Entity name = globaleaks1

Deploy
helm install globaleaks1 -f globaleaks/values.yaml globaleaks/

Upgrade
helm upgrade globaleaks1 -f globaleaks/values.yaml globaleaks/

Undeploy
helm delete globaleaks1

---------
Forked from https://github.com/pablovigo/globaleaks-helm
