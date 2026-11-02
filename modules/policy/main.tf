# Built-in policy definitions, looked up by display name at plan/apply time
# against the tenant's built-in catalog. Nothing here is a custom policy.
data "azurerm_policy_definition" "allowed_locations" {
  display_name = "Allowed locations"
}

data "azurerm_policy_definition" "allowed_vm_skus" {
  display_name = "Allowed virtual machine size SKUs"
}

data "azurerm_policy_definition" "require_tag" {
  display_name = "Require a tag on resource groups"
}

# NOTE on provider versions: azurerm v4 removed the generic
# azurerm_policy_assignment resource. azurerm_resource_policy_assignment is
# its scope-generic successor: resource_id accepts a resource group ID, a
# subscription ID path, or any other resource scope.
resource "azurerm_resource_policy_assignment" "allowed_locations" {
  name                 = "finops-allowed-locations"
  resource_id          = var.scope_id
  policy_definition_id = data.azurerm_policy_definition.allowed_locations.id
  description          = "FinOps guardrail: restrict deployments to approved locations."
  display_name         = "FinOps: allowed locations"
  enforce              = var.enforce

  parameters = jsonencode({
    listOfAllowedLocations = { value = var.allowed_locations }
  })

  non_compliance_message {
    content = "Deployment blocked by FinOps guardrail: location is not in the approved list."
  }
}

resource "azurerm_resource_policy_assignment" "allowed_vm_skus" {
  name                 = "finops-allowed-vm-skus"
  resource_id          = var.scope_id
  policy_definition_id = data.azurerm_policy_definition.allowed_vm_skus.id
  description          = "FinOps guardrail: restrict VM SKUs to approved, cost-bounded sizes."
  display_name         = "FinOps: allowed VM SKUs"
  enforce              = var.enforce

  parameters = jsonencode({
    listOfAllowedSKUs = { value = var.allowed_vm_skus }
  })

  non_compliance_message {
    content = "Deployment blocked by FinOps guardrail: VM SKU is not in the approved list."
  }
}

resource "azurerm_resource_policy_assignment" "require_cost_center_tag" {
  name                 = "finops-require-cost-center-tag"
  resource_id          = var.scope_id
  policy_definition_id = data.azurerm_policy_definition.require_tag.id
  description          = "FinOps guardrail: every resource group must carry a cost-center tag so spend is attributable."
  display_name         = "FinOps: require cost-center tag"
  enforce              = var.enforce

  parameters = jsonencode({
    tagName = { value = var.cost_center_tag_name }
  })

  non_compliance_message {
    content = "Resource group is missing the required cost-center tag."
  }
}
