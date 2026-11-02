# Worked example: one workload resource group with the full guardrail set —
# a budget with 50/80/100% alerts, cost-driver policies scoped to the group,
# and a monthly cost export feeding the reporting script.
resource "azurerm_resource_group" "example" {
  name     = var.resource_group_name
  location = var.location

  tags = {
    CostCenter  = var.cost_center
    Environment = "dev"
    ManagedBy   = "terraform"
  }
}

resource "azurerm_storage_account" "cost_exports" {
  name                     = var.storage_account_name
  resource_group_name      = azurerm_resource_group.example.name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"

  tags = {
    CostCenter  = var.cost_center
    Environment = "dev"
  }
}

module "budgets" {
  source = "../../modules/budgets"

  budget_name         = "finops-example-monthly"
  budget_scope        = "resource_group"
  resource_group_id   = azurerm_resource_group.example.id
  resource_group_name = azurerm_resource_group.example.name
  amount              = var.monthly_budget
  alert_emails        = var.alert_emails
  webhook_url         = var.webhook_url
}

module "policy" {
  source = "../../modules/policy"

  scope_id          = azurerm_resource_group.example.id
  enforce           = true
  allowed_locations = [var.location]
  allowed_vm_skus   = ["Standard_B2s", "Standard_B2ms", "Standard_D2s_v3"]
}

module "cost_export" {
  source = "../../modules/cost-export"

  resource_group_id  = azurerm_resource_group.example.id
  storage_account_id = azurerm_storage_account.cost_exports.id
}
