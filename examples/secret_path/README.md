<!-- BEGIN_TF_DOCS -->
# Example to exercise secrets

This deploys the default nginx container, using a secret volume mount for its configuration.

Additionally, two couple secrets are created, one supplied inline, the second via Keyvault.

TODO the inline secret should be passed via `sensitive_body`

```hcl
# This ensures we have unique CAF compliant names for our resources.
data "azurerm_client_config" "current" {}

module "naming" {
  source  = "Azure/naming/azurerm"
  version = "0.4.0"
}

# This is required for resource modules
resource "azurerm_resource_group" "this" {
  location = "australiaeast"
  name     = module.naming.resource_group.name_unique
}

resource "azurerm_container_app_environment" "this" {
  location            = azurerm_resource_group.this.location
  name                = module.naming.container_app_environment.name_unique
  resource_group_name = azurerm_resource_group.this.name
}

locals {
  test_nginx_config = file("${path.module}/nginx.conf")
}

# create simple KV & KV secret
resource "random_string" "password" {
  length  = 16
  special = false
}

resource "azurerm_key_vault" "this" {
  name                      = module.naming.key_vault.name_unique
  location                  = azurerm_resource_group.this.location
  resource_group_name       = azurerm_resource_group.this.name
  tenant_id                 = data.azurerm_client_config.current.tenant_id
  sku_name                  = "standard"
  enable_rbac_authorization = true
}

resource "azurerm_role_assignment" "current_client" {
  scope                = azurerm_key_vault.this.id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = data.azurerm_client_config.current.object_id
}

resource "time_sleep" "wait_for_role_assignment" {
  create_duration = "30s"
  depends_on      = [azurerm_role_assignment.current_client]
}

resource "azurerm_key_vault_secret" "this" {
  name         = "mysecret"
  value        = random_string.password.result
  key_vault_id = azurerm_key_vault.this.id
  depends_on   = [time_sleep.wait_for_role_assignment]
}

resource "azurerm_role_assignment" "aca" {
  scope                = azurerm_key_vault.this.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = module.container_app.identity.principalId
}

# This is the module call
module "container_app" {
  source = "../../"

  container_app_environment_resource_id = azurerm_container_app_environment.this.id
  location                              = azurerm_resource_group.this.location
  # source             = "Azure/avm-<res/ptn>-<name>/azurerm"
  name                = module.naming.container_app.name_unique
  resource_group_name = azurerm_resource_group.this.name
  template = {
    containers = [{
      image  = "nginx:alpine"
      name   = "nginx"
      cpu    = "0.25"
      memory = "0.5Gi"
      env = [{
        name        = "MY_SIMPLE_SECRET"
        secret_name = "mysimplesecret"
        }, {
        name        = "MY_KV_SECRET"
        secret_name = "mykvsecret"
      }]
      readiness_probes = [{
        initial_delay_seconds = 5
        path                  = "/health"
        period_seconds        = 10
        port                  = 80
        transport             = "HTTP"
      }]
      volume_mounts = [{
        name = "nginx-config"
        path = "/etc/nginx/conf.d"
      }]
    }]
    volumes = [{
      name         = "nginx-config"
      storage_type = "Secret"
      secrets = [{
        secret_name = "nginx-config"
        path        = "default.conf"
      }]
    }]
  }
  ingress = {
    external_enabled = true
    target_port      = 80
  }
  managed_identities = {
    system_assigned = true
  }
  secrets = {
    mykvsecret = {
      key_vault_secret_id = azurerm_key_vault_secret.this.versionless_id
      identity            = "system"
      name                = "mykvsecret"
    }
    mysimplesecret = {
      name  = "mysimplesecret"
      value = "muchbettertousekeyvault"
    }
    nginx_config = {
      name  = "nginx-config"
      value = local.test_nginx_config
    }
  }
}
```

<!-- markdownlint-disable MD033 -->
## Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) (>= 1.9, < 2.0)

- <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) (>= 4.20.0, < 5.0)

- <a name="requirement_random"></a> [random](#requirement\_random) (>= 3.7, < 4.0)

- <a name="requirement_time"></a> [time](#requirement\_time) (>= 0.13, < 1.0)

## Resources

The following resources are used by this module:

- [azurerm_container_app_environment.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/container_app_environment) (resource)
- [azurerm_key_vault.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/key_vault) (resource)
- [azurerm_key_vault_secret.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/key_vault_secret) (resource)
- [azurerm_resource_group.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group) (resource)
- [azurerm_role_assignment.aca](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) (resource)
- [azurerm_role_assignment.current_client](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) (resource)
- [random_string.password](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/string) (resource)
- [time_sleep.wait_for_role_assignment](https://registry.terraform.io/providers/hashicorp/time/latest/docs/resources/sleep) (resource)
- [azurerm_client_config.current](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/client_config) (data source)

<!-- markdownlint-disable MD013 -->
## Required Inputs

No required inputs.

## Optional Inputs

No optional inputs.

## Outputs

The following outputs are exported:

### <a name="output_test_app_url"></a> [test\_app\_url](#output\_test\_app\_url)

Description: n/a

## Modules

The following Modules are called:

### <a name="module_container_app"></a> [container\_app](#module\_container\_app)

Source: ../../

Version:

### <a name="module_naming"></a> [naming](#module\_naming)

Source: Azure/naming/azurerm

Version: 0.4.0

<!-- markdownlint-disable-next-line MD041 -->
## Data Collection

The software may collect information about you and your use of the software and send it to Microsoft. Microsoft may use this information to provide services and improve our products and services. You may turn off the telemetry as described in the repository. There are also some features in the software that may enable you and Microsoft to collect data from users of your applications. If you use these features, you must comply with applicable law, including providing appropriate notices to users of your applications together with a copy of Microsoft’s privacy statement. Our privacy statement is located at <https://go.microsoft.com/fwlink/?LinkID=824704>. You can learn more about data collection and use in the help documentation and our privacy statement. Your use of the software operates as your consent to these practices.
<!-- END_TF_DOCS -->