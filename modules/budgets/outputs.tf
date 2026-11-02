output "budget_id" {
  description = "ID of the created budget (resource-group or subscription scope)."
  value = var.budget_scope == "resource_group" ? (
    azurerm_consumption_budget_resource_group.this[0].id
    ) : (
    azurerm_consumption_budget_subscription.this[0].id
  )
}

output "action_group_id" {
  description = "ID of the action group wired to every budget notification."
  value       = azurerm_monitor_action_group.finops.id
}
