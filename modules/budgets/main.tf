# Action group: every budget notification below routes through this group,
# so email and webhook handling lives in exactly one place.
resource "azurerm_monitor_action_group" "finops" {
  name                = "${var.budget_name}-ag"
  resource_group_name = var.resource_group_name
  short_name          = "finops"

  email_receiver {
    name          = "finops-alerts"
    email_address = var.alert_emails[0]
  }

  dynamic "webhook_receiver" {
    for_each = var.webhook_url != "" ? [1] : []
    content {
      name        = "finops-webhook"
      service_uri = var.webhook_url
    }
  }
}

resource "azurerm_consumption_budget_resource_group" "this" {
  count = var.budget_scope == "resource_group" ? 1 : 0

  name              = var.budget_name
  resource_group_id = var.resource_group_id
  amount            = var.amount
  time_grain        = var.time_grain

  time_period {
    start_date = var.start_date
    end_date   = var.end_date != "" ? var.end_date : null
  }

  dynamic "notification" {
    for_each = var.thresholds
    content {
      enabled        = true
      operator       = notification.value.operator
      threshold      = notification.value.threshold
      threshold_type = notification.value.threshold_type
      contact_emails = var.alert_emails
      contact_groups = [azurerm_monitor_action_group.finops.id]
    }
  }
}

resource "azurerm_consumption_budget_subscription" "this" {
  count = var.budget_scope == "subscription" ? 1 : 0

  name            = var.budget_name
  subscription_id = var.subscription_id
  amount          = var.amount
  time_grain      = var.time_grain

  time_period {
    start_date = var.start_date
    end_date   = var.end_date != "" ? var.end_date : null
  }

  dynamic "notification" {
    for_each = var.thresholds
    content {
      enabled        = true
      operator       = notification.value.operator
      threshold      = notification.value.threshold
      threshold_type = notification.value.threshold_type
      contact_emails = var.alert_emails
      contact_groups = [azurerm_monitor_action_group.finops.id]
    }
  }
}
