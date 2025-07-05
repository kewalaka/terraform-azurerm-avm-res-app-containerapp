# Example to exercise secrets

This deploys the default nginx container, using a secret volume mount for its configuration.

Additionally, two couple secrets are created, one supplied inline, the second via Keyvault.

TODO the inline secret should be passed via `sensitive_body`
