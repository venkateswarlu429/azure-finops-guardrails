variable "location" {
  description = "Azure region for the example workload."
  type        = string
  default     = "eastus"
}

variable "resource_group_name" {
  description = "Name of the example workload resource group."
  type        = string
  default     = "rg-finops-example-dev"
}

variable "cost_center" {
  description = "Cost-center tag value applied to the example resource group."
  type        = string
  default     = "finops-example"
}

variable "storage_account_name" {
  description = "Globally unique storage account name for cost exports. CHANGE the default — it is a placeholder, not a real account."
  type        = string
  default     = "finopsexample00000"
}

variable "monthly_budget" {
  description = "Example monthly budget amount for the workload resource group."
  type        = number
  default     = 500
}

variable "alert_emails" {
  description = "Email addresses for budget alerts. Replace the placeholder before applying."
  type        = list(string)
  default     = ["finops-alerts@example.invalid"]
}

variable "webhook_url" {
  description = "Optional webhook URL for budget alerts. Leave empty to skip."
  type        = string
  default     = ""
  sensitive   = true
}
