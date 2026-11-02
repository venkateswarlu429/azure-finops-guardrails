output "export_id" {
  description = "ID of the scheduled cost export."
  value       = azurerm_resource_group_cost_management_export.this.id
}

output "container_id" {
  description = "ID of the blob container receiving the exported cost files."
  value       = azurerm_storage_container.cost_exports.id
}
