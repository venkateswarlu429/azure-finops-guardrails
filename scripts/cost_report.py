#!/usr/bin/env python3
"""Cost report for Azure Cost Management.

Queries actual costs for a subscription (optionally scoped to one resource
group), grouped by resource group and by service, and compares the total
against a budget amount when one is supplied.

Credentials: uses DefaultAzureCredential (environment variables, managed
identity, Azure CLI login, etc.). No credentials, subscription IDs, or
secrets are stored in this file — everything comes from flags or the
environment.

Usage:
    pip install azure-identity azure-mgmt-costmanagement
    export AZURE_SUBSCRIPTION_ID="00000000-0000-0000-0000-000000000000"
    python3 scripts/cost_report.py --start 2026-01-01 --end 2026-01-31 --budget 500

Without AZURE_SUBSCRIPTION_ID (or --subscription) the script prints usage
and exits. It never prints invented numbers: every figure in its output
comes from the Cost Management query response.
"""

import argparse
import os
import sys
from collections import defaultdict
from datetime import date


def parse_args(argv=None):
    parser = argparse.ArgumentParser(
        description="Summarize Azure costs by resource group and service, "
        "with an optional budget-vs-actual comparison."
    )
    parser.add_argument(
        "--subscription",
        default=os.environ.get("AZURE_SUBSCRIPTION_ID", ""),
        help="Azure subscription ID (or set AZURE_SUBSCRIPTION_ID).",
    )
    parser.add_argument(
        "--resource-group",
        default=os.environ.get("AZURE_RESOURCE_GROUP", ""),
        help="Optional: scope the query to one resource group.",
    )
    parser.add_argument(
        "--start",
        default="",
        help="Start date YYYY-MM-DD (default: first day of the current month).",
    )
    parser.add_argument(
        "--end",
        default="",
        help="End date YYYY-MM-DD (default: today).",
    )
    parser.add_argument(
        "--budget",
        type=float,
        default=float(os.environ.get("BUDGET_AMOUNT", "0") or 0),
        help="Budget amount to compare actuals against (or set BUDGET_AMOUNT).",
    )
    return parser.parse_args(argv)


def default_period():
    today = date.today()
    return today.replace(day=1).isoformat(), today.isoformat()


def query_costs(subscription_id, resource_group, start, end):
    """Run the Cost Management query. SDK imports live here so that
    --help works without the Azure packages installed."""
    try:
        from azure.identity import DefaultAzureCredential
        from azure.mgmt.costmanagement import CostManagementClient
        from azure.mgmt.costmanagement.models import (
            QueryAggregation,
            QueryDataset,
            QueryDefinition,
            QueryGrouping,
        )
    except ImportError:
        print(
            "Missing Azure SDK packages. Install them first:\n"
            "    pip install azure-identity azure-mgmt-costmanagement",
            file=sys.stderr,
        )
        raise SystemExit(2)

    if resource_group:
        scope = (
            f"subscriptions/{subscription_id}/resourceGroups/{resource_group}"
        )
    else:
        scope = f"subscriptions/{subscription_id}"

    client = CostManagementClient(
        credential=DefaultAzureCredential(), subscription_id=subscription_id
    )
    definition = QueryDefinition(
        type="ActualCost",
        timeframe="Custom",
        time_period={"from": start, "to": end},
        dataset=QueryDataset(
            granularity="Daily",
            aggregation={
                "totalCost": QueryAggregation(name="Cost", function="Sum")
            },
            grouping=[
                QueryGrouping(type="Dimension", name="ResourceGroup"),
                QueryGrouping(type="Dimension", name="ServiceName"),
            ],
        ),
    )
    result = client.query.usage(scope, definition)
    return result.rows or []


def summarize(rows):
    """Aggregate query rows into totals by resource group and by service.

    Row shape from the API: [cost, date (epoch ms), resource_group,
    service_name]. Parsing is defensive: rows that do not fit are skipped
    rather than guessed at.
    """
    by_group = defaultdict(float)
    by_service = defaultdict(float)
    total = 0.0
    for row in rows:
        if len(row) < 4:
            continue
        try:
            cost = float(row[0])
        except (TypeError, ValueError):
            continue
        total += cost
        by_group[str(row[2])] += cost
        by_service[str(row[3])] += cost
    return total, by_group, by_service


def print_table(title, items, total):
    print(f"\n{title}")
    print("-" * len(title))
    for name, cost in sorted(items.items(), key=lambda kv: -kv[1]):
        share = (cost / total * 100) if total else 0.0
        print(f"  {name:<45} {cost:>12.2f}  ({share:5.1f}%)")
    if not items:
        print("  (no rows returned)")


def main(argv=None):
    args = parse_args(argv)
    if not args.subscription:
        print(
            "AZURE_SUBSCRIPTION_ID is not set. Pass --subscription or export "
            "AZURE_SUBSCRIPTION_ID, then re-run.",
            file=sys.stderr,
        )
        return 2

    start, end = args.start, args.end
    if not start or not end:
        default_start, default_end = default_period()
        start = start or default_start
        end = end or default_end

    scope_label = (
        f"resource group {args.resource_group}"
        if args.resource_group
        else f"subscription {args.subscription}"
    )
    print(f"Cost report: {scope_label}  ({start} to {end})")

    rows = query_costs(args.subscription, args.resource_group, start, end)
    total, by_group, by_service = summarize(rows)

    print(f"\nTotal actual cost: {total:.2f}")
    print_table("By resource group", by_group, total)
    print_table("By service", by_service, total)

    if args.budget > 0:
        used = (total / args.budget * 100) if args.budget else 0.0
        remaining = args.budget - total
        status = "OVER BUDGET" if total > args.budget else "within budget"
        print(f"\nBudget: {args.budget:.2f}  |  Actual: {total:.2f}  |  "
              f"Used: {used:.1f}%  |  Remaining: {remaining:.2f}  |  {status}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
