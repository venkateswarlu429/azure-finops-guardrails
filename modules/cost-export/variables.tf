variable "export_name" {
  description = "Name of the scheduled cost export."
  type        = string
  default     = "finops-monthly-export"
}

variable "resource_group_id" {
  description = "Full Azure ID of the resource group the export is scoped to."
  type        = string
}

variable "storage_account_id" {
  description = "Full Azure ID of the storage account receiving the export files (the export container is created in it)."
  type        = string
}

variable "container_name" {
  description = "Blob container that receives the exported cost files."
  type        = string
  default     = "cost-exports"
}

variable "root_folder_path" {
  description = "Folder prefix inside the container for exported files."
  type        = string
  default     = "finops"
}

variable "recurrence_type" {
  description = "Export recurrence: Daily, Weekly, or Monthly."
  type        = string
  default     = "Monthly"
}

variable "start_date" {
  description = "Export schedule start date (YYYY-MM-DD)."
  type        = string
  default     = "2026-01-01"
}

variable "end_date" {
  description = "Export schedule end date (YYYY-MM-DD). Required by the provider; use a far-future date for an ongoing export."
  type        = string
  default     = "2030-01-01"
}
