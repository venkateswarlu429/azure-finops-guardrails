# The export lands as CSV in blob storage, which downstream reporting reads.
# Export files are the raw material for the "inform" half of the FinOps loop;
# the budgets and policies are the control half.
#
# NOTE on provider versions: azurerm v4 renamed this resource from
# azurerm_cost_management_export_resource_group to
# azurerm_resource_group_cost_management_export, and moved the dataset
# configuration out: type/timeframe live in export_data_options, and the
# storage location takes only the container (the account is implied).
resource "azurerm_storage_container" "cost_exports" {
  name                  = var.container_name
  storage_account_id    = var.storage_account_id
  container_access_type = "private"
}

resource "azurerm_resource_group_cost_management_export" "this" {
  name                         = var.export_name
  resource_group_id            = var.resource_group_id
  recurrence_type              = var.recurrence_type
  recurrence_period_start_date = var.start_date
  recurrence_period_end_date   = var.end_date
  file_format                  = "Csv"
  active                       = true

  export_data_options {
    type       = "ActualCost"
    time_frame = "MonthToDate"
  }

  export_data_storage_location {
    container_id     = azurerm_storage_container.cost_exports.id
    root_folder_path = var.root_folder_path
  }
}
