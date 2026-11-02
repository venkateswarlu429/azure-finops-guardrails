# Azure FinOps Guardrails

FinOps cost guardrails and reporting for Azure, as code: budgets with
alerts, Azure Policy enforcement on cost drivers, scheduled cost exports,
and a Python cost-reporting script.

> **Scope, stated plainly:** this is a purpose-built project demonstrating
> FinOps guardrails as code. It is **not** a claim of production FinOps
> ownership, **not** a FinOps certification, and it has **never been
> applied to a live subscription**. Nothing here reports real spend or
> real savings — the only figures in this repo are labeled examples.

## The FinOps loop this implements

| Stage | What | Where |
| --- | --- | --- |
| **Inform** | Recurring ActualCost exports to blob storage + an on-demand cost report grouped by resource group and service | `modules/cost-export/`, `scripts/cost_report.py` |
| **Optimize** | Policy guardrails that block the cost drivers before they happen: unapproved regions, oversized VM SKUs, untagged resource groups | `modules/policy/` |
| **Operate** | Budgets with 50/80/100% alerts wired to one action group (email + optional webhook) | `modules/budgets/` |

Budgets alone only tell you after the money is spent. Policies alone only
say no. The point of keeping all three together is the loop: the report
shows where spend concentrates, the policies stop the next occurrence,
and the budget alerts catch what slips through.

## Layout

```
modules/
  budgets/        Cost Management budget (resource-group or subscription
                  scope) + monitor action group; thresholds default to
                  50% actual, 80% actual, 100% forecasted
  policy/         Built-in policy assignments: allowed locations, allowed
                  VM SKUs, require a cost-center tag on resource groups;
                  enforce=true, or audit-only via enforce=false
  cost-export/    Scheduled ActualCost export to a private blob container
environments/
  dev/            Worked example: one workload resource group with the full
                  guardrail set applied, plus terraform.tfvars.example
scripts/
  cost_report.py  Azure Cost Management query: per-resource-group and
                  per-service totals with a budget-vs-actual comparison
.github/
  workflows/ci.yml  fmt check + terraform validate per module + Python
                    syntax check
```

## Modules

### budgets

Creates a Cost Management budget and one monitor action group that every
notification routes through. Thresholds are a list, so adding a 90%
forecasted alert is one line. Scope is a variable: `resource_group` or
`subscription`. Alert emails default to a placeholder
(`finops-alerts@example.invalid`) that must be replaced at apply time;
the webhook receiver is only created when a URL is supplied.

### policy

Three built-in policy assignments, looked up by display name at
plan/apply time — no custom policy JSON is maintained here:

- **Allowed locations** — deployments outside the approved list are denied.
- **Allowed virtual machine size SKUs** — blocks large, expensive SKUs
  by default; the approved list is a variable.
- **Require a tag on resource groups** — every resource group must carry
  the cost-center tag, otherwise cost reports cannot attribute spend.

Set `enforce = false` to onboard a scope in audit-only mode first, then
flip it to enforcing once the non-compliance report is clean.

### cost-export

A private blob container plus a recurring ActualCost export into it, so
there is always a raw spend record independent of the portal. The
reporting script queries the Cost Management API directly rather than
parsing these files, so the two paths cross-check each other.

## Worked example

```bash
cd environments/dev
cp terraform.tfvars.example terraform.tfvars   # replace every placeholder
terraform init
terraform plan
terraform apply
```

The example creates a resource group tagged with a cost center, a storage
account for exports, a monthly budget with the default thresholds, the
three policies scoped to the group, and the monthly export. The storage
account name in the example is a placeholder and must be changed — it has
to be globally unique.

## Cost report script

```bash
pip install azure-identity azure-mgmt-costmanagement
export AZURE_SUBSCRIPTION_ID="00000000-0000-0000-0000-000000000000"  # placeholder
python3 scripts/cost_report.py --start 2026-01-01 --end 2026-01-31 --budget 500
```

`--resource-group` scopes the query to one group; `--budget` (or
`BUDGET_AMOUNT`) adds the budget-vs-actual comparison. Without a
subscription ID the script prints usage and exits — it never prints
invented numbers. Authentication is `DefaultAzureCredential` (environment,
managed identity, or Azure CLI login).

EXAMPLE OUTPUT (illustrative only — not real data):

```
Cost report: subscription 00000000-0000-0000-0000-000000000000  (2026-01-01 to 2026-01-31)

Total actual cost: 412.50

By resource group
-----------------
  rg-finops-example-dev                           412.50  (100.0%)

By service
----------
  Virtual Machines                                260.00  ( 63.0%)
  Storage                                         152.50  ( 37.0%)

Budget: 500.00  |  Actual: 412.50  |  Used: 82.5%  |  Remaining: 87.50  |  within budget
```

## Validation — what was actually checked

Validated here, with Terraform v1.17.1 (installed for this repo) and the
current azurerm provider schemas:

- `terraform fmt -check -recursive` — clean.
- `terraform init -backend=false` + `terraform validate` — **Success**
  for all four configurations: `modules/budgets`, `modules/policy`,
  `modules/cost-export`, `environments/dev`.
- `python3 -m py_compile scripts/cost_report.py` — clean.
- `python3 scripts/cost_report.py --help` — works without the Azure SDK
  installed (SDK imports are deferred to query time).
- `python3 scripts/cost_report.py` with no credentials — exits with a
  clear usage message, never with fabricated figures.

**Not validated, and not claimed:** `terraform plan` / `apply` against a
live subscription, any real cost data, and any savings amount. The
policy definition lookups resolve at plan/apply time against the tenant's
built-in catalog, and the example storage account name must be replaced
with a globally unique one.

Provider notes (azurerm v4): policy assignments use the scope-generic
`azurerm_resource_policy_assignment` (the old generic
`azurerm_policy_assignment` was removed in v4); cost exports use
`azurerm_resource_group_cost_management_export` (renamed in v4, with
type/timeframe in `export_data_options`); storage containers take
`storage_account_id`, not `storage_account_name`. Validation caught all
three of these — the first version of this repo used the older names
and was fixed to the v4 schema before publishing.

## Placeholders

No real subscription IDs, tenant IDs, email addresses, webhook URLs, or
secrets appear anywhere in this repo. Every such value is a placeholder
(`example.invalid` mail domain, all-zero IDs, empty webhook) or an
environment variable to be supplied at run time.

## License

MIT — © 2026 Venkateswarlu Maddula.
