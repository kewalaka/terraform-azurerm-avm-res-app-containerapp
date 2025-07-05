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
  location                  = azurerm_resource_group.this.location
  name                      = module.naming.key_vault.name_unique
  resource_group_name       = azurerm_resource_group.this.name
  sku_name                  = "standard"
  tenant_id                 = data.azurerm_client_config.current.tenant_id
  enable_rbac_authorization = true
}

resource "azurerm_role_assignment" "current_client" {
  principal_id         = data.azurerm_client_config.current.object_id
  scope                = azurerm_key_vault.this.id
  role_definition_name = "Key Vault Secrets Officer"
}

resource "time_sleep" "wait_for_role_assignment" {
  create_duration = "30s"

  depends_on = [azurerm_role_assignment.current_client]
}

resource "azurerm_key_vault_secret" "this" {
  key_vault_id = azurerm_key_vault.this.id
  name         = "mysecret"
  value        = random_string.password.result

  depends_on = [time_sleep.wait_for_role_assignment]
}

resource "azurerm_role_assignment" "aca" {
  principal_id         = module.container_app.identity.principalId
  scope                = azurerm_key_vault.this.id
  role_definition_name = "Key Vault Secrets User"
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
