terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

variable "subscription_id" { type = string }
variable "alert_email"     { type = string }

provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}

locals {
  location = "uaenorth"
  tags     = { owner = "junaid", environment = "lab", project = "azure-landing-zone" }
}

# --- Resource groups ---
resource "azurerm_resource_group" "governance" {
  name     = "rg-lz-governance"
  location = local.location
  tags     = local.tags
}

resource "azurerm_resource_group" "workload" {
  name     = "rg-lz-workload"
  location = local.location
  tags     = local.tags
}

# --- Azure Policy on the workload RG ---
resource "azurerm_resource_group_policy_assignment" "allowed_locations" {
  name                 = "allowed-locations"
  display_name         = "Allowed locations: UAE North only"
  resource_group_id    = azurerm_resource_group.workload.id
  policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/e56962a6-4747-49cd-b67b-bf8b01975c4c"
  parameters = jsonencode({
    listOfAllowedLocations = { value = [local.location] }
  })
}

resource "azurerm_resource_group_policy_assignment" "require_owner_tag" {
  name                 = "require-owner-tag"
  display_name         = "Require tag: owner"
  resource_group_id    = azurerm_resource_group.workload.id
  policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/871b6d14-10aa-478d-b590-94f262ecfa99"
  parameters = jsonencode({
    tagName = { value = "owner" }
  })
}

resource "azurerm_resource_group_policy_assignment" "secure_transfer" {
  name                 = "secure-transfer-storage"
  display_name         = "Storage accounts: secure transfer required"
  resource_group_id    = azurerm_resource_group.workload.id
  policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/404c3081-a854-4457-ae30-26a93ef643f9"
  parameters = jsonencode({
    effect = { value = "Deny" }
  })
}

# --- Delete lock on governance RG ---
resource "azurerm_management_lock" "governance" {
  name       = "lock-no-delete"
  scope      = azurerm_resource_group.governance.id
  lock_level = "CanNotDelete"
  notes      = "Protects governance resources from accidental deletion"
}

# --- Logging: Log Analytics + subscription activity log ---
resource "azurerm_log_analytics_workspace" "gov" {
  name                = "law-lz-governance"
  location            = azurerm_resource_group.governance.location
  resource_group_name = azurerm_resource_group.governance.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
  tags                = local.tags
}

resource "azurerm_monitor_diagnostic_setting" "activity_log" {
  name                       = "diag-activity-log"
  target_resource_id         = "/subscriptions/${var.subscription_id}"
  log_analytics_workspace_id = azurerm_log_analytics_workspace.gov.id

  enabled_log { category = "Administrative" }
  enabled_log { category = "Policy" }
  enabled_log { category = "Security" }
  enabled_log { category = "Alert" }
}

# --- Budget: $5 on the workload RG, alert at 80% ---
resource "azurerm_consumption_budget_resource_group" "workload" {
  name              = "budget-lz-workload"
  resource_group_id = azurerm_resource_group.workload.id
  amount            = 5
  time_grain        = "Monthly"

  time_period {
    start_date = "2026-11-01T00:00:00Z"
  }

  notification {
    enabled        = true
    threshold      = 80
    operator       = "GreaterThan"
    threshold_type = "Actual"
    contact_emails = [var.alert_email]
  }
}
