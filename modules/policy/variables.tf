variable "scope_id" {
  description = "Azure scope the assignments attach to (subscription ID path or resource group ID)."
  type        = string
}

variable "enforce" {
  description = "True = Deny effect enforced; false = audit-only (DoNotEnforce) for onboarding."
  type        = bool
  default     = true
}

variable "allowed_locations" {
  description = "Locations workloads may deploy to. Cost driver: keeps spend in priced, approved regions."
  type        = list(string)
  default     = ["eastus"]
}

variable "allowed_vm_skus" {
  description = "VM SKUs workloads may use. Cost driver: blocks large, expensive SKUs by default."
  type        = list(string)
  default     = ["Standard_B2s", "Standard_B2ms", "Standard_D2s_v3"]
}

variable "cost_center_tag_name" {
  description = "Tag that every resource group must carry so cost reports can attribute spend."
  type        = string
  default     = "CostCenter"
}
