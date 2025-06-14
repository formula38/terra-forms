import argparse
import json
from pricing import get_live_price
from utils import infer_module, format_cost

# Static fallback prices (used when --live is False or pricing fails)
STATIC_PRICES = {
    "aws_instance": 25.0,
    "aws_s3_bucket": 0.02,
    "aws_cloudfront_distribution": 2.5,
    "aws_iam_role": 0.0,
    "aws_kms_key": 1.0,
    "aws_db_instance": 20.0,
    "aws_subnet": 0.0,
    "aws_security_group": 0.0,
    "aws_vpc": 0.0,
    "aws_lambda_function": 1.5,
    "default": 0.5
}

def estimate_cost(resource_type, live=False, cache={}):
    if live:
        if resource_type in cache:
            return cache[resource_type]
        price = get_live_price(resource_type)
        if price is not None:
            cache[resource_type] = price
            return price
    return STATIC_PRICES.get(resource_type, STATIC_PRICES["default"])

def summarize_costs(plan_path, live=False):
    with open(plan_path, "r") as f:
        plan = json.load(f)

    resource_changes = plan.get("resource_changes", [])
    summary = {"create": [], "update": [], "delete": [], "other": []}
    total_cost = 0.0

    for change in resource_changes:
        actions = change.get("change", {}).get("actions", [])
        r_type = change.get("type")
        action_type = next((a for a in ["create", "update", "delete"] if a in actions), "other")
        cost = estimate_cost(r_type, live=live)
        summary[action_type].append((change, cost))
        if action_type == "create":
            total_cost += cost

    return summary, total_cost

def display_summary(summary, total_cost):
    print("\n💰 Terraform Monthly Cost Summary")
    print("-" * 40)
    for action in ["create", "update", "delete", "other"]:
        print(f"{action.upper():<10}: {len(summary[action])} resources")
    print("-" * 40)
    print(f"Estimated Total Monthly Cost: {format_cost(total_cost)}\n")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Estimate monthly cost from Terraform plan")
    parser.add_argument("--plan", required=True, help="Path to terraform plan JSON")
    parser.add_argument("--live", action="store_true", help="Use live AWS pricing")
    parser.add_argument("--summary", action="store_true", help="Print cost summary to console")

    args = parser.parse_args()
    summary, total = summarize_costs(args.plan, live=args.live)
    
    if args.summary:
        display_summary(summary, total)
