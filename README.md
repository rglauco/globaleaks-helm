# globaleaks-helm

<div align="center">
 <a href="https://www.globaleaks.org"><img src="https://raw.githubusercontent.com/globaleaks/GlobaLeaks/main/brand/assets/globaleaks-logo-color.png" width="400"></a>
</div>

<div align="center">
  <a href="https://github.com/globaleaks/GlobaLeaks/blob/main/LICENSE"><img src="https://img.shields.io/badge/license-AGPLv3%2B-green" alt="License"></a> <a href="https://github.com/globaleaks/GlobaLeaks/blob/main/CODE_OF_CONDUCT.md"><img src="https://img.shields.io/badge/Contributor%20Covenant-v2.0%20adopted-ff69b4.svg" alt="Code of Conduct"></a> <a href="https://twitter.com/intent/follow?screen_name=GlobaLeaks"><img src="https://img.shields.io/twitter/follow/GlobaLeaks?style=social&logo=twitter" alt="follow on Twitter"></a>
</div>

[GlobaLeaks](https://www.globaleaks.org/) is free, open source software enabling anyone to easily set up and maintain a secure whistleblowing platform.
## Documentation
GlobaLeaks's documentation is accessible at: [docs.globaleaks.org](https://docs.globaleaks.org)

## Deployment

Entity name = guinardo

Deploy
helm install guinardo -f globaleaks/values.yaml globaleaks/

Upgrade
helm upgrade guinardo -f globaleaks/values.yaml globaleaks/

Undeploy
helm delete guinardo
