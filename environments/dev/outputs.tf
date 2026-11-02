output "budget_id" {
  value = module.budgets.budget_id
}

output "action_group_id" {
  value = module.budgets.action_group_id
}

output "policy_assignment_ids" {
  value = module.policy.assignment_ids
}

output "cost_export_id" {
  value = module.cost_export.export_id
}
