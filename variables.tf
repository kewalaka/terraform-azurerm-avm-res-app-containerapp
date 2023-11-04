variable "enable_telemetry" {
  type        = bool
  default     = false
  description = <<DESCRIPTION
This variable controls whether or not telemetry is enabled for the module.
For more information see https://aka.ms/avm/telemetryinfo.
If it is set to false, then no telemetry will be collected.
DESCRIPTION
}

# This is required for most resource modules
variable "resource_group_name" {
  type        = string
  description = "The resource group where the resources will be deployed."
}


//required AVM interfaces

# variable "diagnostic_settings" {
#   type = map(object({
#     name                                     = optional(string, null)
#     log_categories_and_groups                = optional(set(string), ["allLogs"])
#     metric_categories                        = optional(set(string), ["AllMetrics"])
#     log_analytics_destination_type           = optional(string, "Dedicated")
#     workspace_resource_id                    = optional(string, null)
#     storage_account_resource_id              = optional(string, null)
#     event_hub_authorization_rule_resource_id = optional(string, null)
#     event_hub_name                           = optional(string, null)
#     marketplace_partner_resource_id          = optional(string, null)
#   }))
#   default  = {}
#   nullable = false

#   validation {
#     condition     = alltrue([for _, v in var.diagnostic_settings : contains(["Dedicated", "AzureDiagnostics"], v.log_analytics_destination_type)])
#     error_message = "Log analytics destination type must be one of: 'Dedicated', 'AzureDiagnostics'."
#   }
# }


# variable "role_assignments" {
#   type = map(object({
#     role_definition_id_or_name             = string
#     principal_id                           = string
#     description                            = optional(string, null)
#     skip_service_principal_aad_check       = optional(bool, true)
#     condition                              = optional(string, null)
#     condition_version                      = optional(string, "2.0")
#     delegated_managed_identity_resource_id = optional(string)
#   }))
#   default = {}
# }

# variable "lock" {
#   type = object({
#     name = optional(string, null)
#     kind = optional(string, "None")


#   })
#   description = "The lock level to apply to the Container App. Default is `None`. Possible values are `None`, `CanNotDelete`, and `ReadOnly`."
#   default     = {}
#   nullable    = false
#   validation {
#     condition     = contains(["CanNotDelete", "ReadOnly", "None"], var.lock.kind)
#     error_message = "The lock level must be one of: 'None', 'CanNotDelete', or 'ReadOnly'."
#   }
# }
