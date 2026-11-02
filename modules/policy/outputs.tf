output "assignment_ids" {
  description = "IDs of the three FinOps policy assignments."
  value = {
    allowed_locations = azurerm_resource_policy_assignment.allowed_locations.id
    allowed_vm_skus   = azurerm_resource_policy_assignment.allowed_vm_skus.id
    require_tag       = azurerm_resource_policy_assignment.require_cost_center_tag.id
  }
}
