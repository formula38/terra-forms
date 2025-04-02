from pricing import get_aws_pricing

def estimate_cost(resource):
    resource_type = resource.get("type")

    # Heuristic map for service code and filter setup
    pricing_map = {
        "aws_instance": {
            "service": "AmazonEC2",
            "filters": [
                {"Type": "TERM_MATCH", "Field": "instanceType", "Value": "t3.micro"},
                {"Type": "TERM_MATCH", "Field": "location", "Value": "US East (N. Virginia)"},
                {"Type": "TERM_MATCH", "Field": "operatingSystem", "Value": "Linux"},
                {"Type": "TERM_MATCH", "Field": "preInstalledSw", "Value": "NA"},
                {"Type": "TERM_MATCH", "Field": "tenancy", "Value": "Shared"},
                {"Type": "TERM_MATCH", "Field": "capacitystatus", "Value": "Used"},
            ]
        },
        "aws_s3_bucket": {
            "service": "AmazonS3",
            "filters": [
                {"Type": "TERM_MATCH", "Field": "location", "Value": "US East (N. Virginia)"},
                {"Type": "TERM_MATCH", "Field": "storageClass", "Value": "Standard"},
                {"Type": "TERM_MATCH", "Field": "productFamily", "Value": "Storage"},
            ]
        },
        # Add more mappings as needed
    }

    pricing_data = pricing_map.get(resource_type)
    if pricing_data:
        live_price = get_aws_pricing(
            pricing_data["service"],
            filters=pricing_data["filters"]
        )
        if live_price is not None:
            return live_price

    # fallback
    return 0.5
