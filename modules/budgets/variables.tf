variable "budget_name" {
  description = "Name of the Cost Management budget."
  type        = string
  default     = "finops-monthly-budget"
}

variable "budget_scope" {
  description = "Scope of the budget: \"resource_group\" or \"subscription\"."
  type        = string
  default     = "resource_group"

  validation {
    condition     = contains(["resource_group", "subscription"], var.budget_scope)
    error_message = "budget_scope must be \"resource_group\" or \"subscription\"."
  }
}

variable "resource_group_id" {
  description = "Full Azure ID of the resource group (required when budget_scope is \"resource_group\")."
  type        = string
  default     = ""
}

variable "resource_group_name" {
  description = "Name of the resource group that owns the action group."
  type        = string
}

variable "subscription_id" {
  description = "Subscription ID (required when budget_scope is \"subscription\"). Placeholder only — never commit a real ID."
  type        = string
  default     = ""
}

variable "amount" {
  description = "Monthly budget amount in the subscription currency."
  type        = number
  default     = 500
}

variable "time_grain" {
  description = "Budget time grain: Monthly, Quarterly, or Annually."
  type        = string
  default     = "Monthly"
}

variable "start_date" {
  description = "Budget start date (YYYY-MM-DD)."
  type        = string
  default     = "2026-01-01"
}

variable "end_date" {
  description = "Budget end date (YYYY-MM-DD). Leave empty for an open-ended budget."
  type        = string
  default     = ""
}

variable "thresholds" {
  description = "Alert thresholds as percentages of the budget. Each entry sets one notification."
  type = list(object({
    threshold      = number
    threshold_type = string # Actual or Forecasted
    operator       = string # EqualTo or GreaterThan
  }))
  default = [
    { threshold = 50, threshold_type = "Actual", operator = "GreaterThan" },
    { threshold = 80, threshold_type = "Actual", operator = "GreaterThan" },
    { threshold = 100, threshold_type = "Forecasted", operator = "GreaterThan" },
  ]
}

variable "alert_emails" {
  description = "Email addresses notified when a threshold trips. Replace the placeholder with real addresses at apply time."
  type        = list(string)
  default     = ["finops-alerts@example.invalid"]
}

variable "webhook_url" {
  description = "Optional webhook URL for the action group (e.g. a Teams/Logic App endpoint). Leave empty to skip the webhook receiver."
  type        = string
  default     = ""
  sensitive   = true
}
