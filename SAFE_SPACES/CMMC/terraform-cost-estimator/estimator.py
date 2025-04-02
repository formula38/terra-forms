from pricing import get_aws_pricing

def estimate_cost(resource):
    resource_type = resource.get("type")
    name = resource.get("name", "unknown")

    # Map resource types to AWS service and common filters
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
        "aws_db_instance": {
            "service": "AmazonRDS",
            "filters": [
                {"Type": "TERM_MATCH", "Field": "instanceType", "Value": "db.t3.micro"},
                {"Type": "TERM_MATCH", "Field": "databaseEngine", "Value": "MySQL"},
                {"Type": "TERM_MATCH", "Field": "location", "Value": "US East (N. Virginia)"},
                {"Type": "TERM_MATCH", "Field": "deploymentOption", "Value": "Single-AZ"},
            ]
        },
        "aws_lambda_function": {
            "service": "AWSLambda",
            "filters": [
                {"Type": "TERM_MATCH", "Field": "location", "Value": "US East (N. Virginia)"},
                {"Type": "TERM_MATCH", "Field": "group", "Value": "AWS Lambda"},
                {"Type": "TERM_MATCH", "Field": "usagetype", "Value": "Request"},
            ]
        },
        "aws_cloudfront_distribution": {
            "service": "AmazonCloudFront",
            "filters": [
                {"Type": "TERM_MATCH", "Field": "group", "Value": "Amazon CloudFront"},
                {"Type": "TERM_MATCH", "Field": "location", "Value": "United States"},
            ]
        },
        "aws_kms_key": {
            "service": "AWSKeyManagementService",
            "filters": [
                {"Type": "TERM_MATCH", "Field": "location", "Value": "US East (N. Virginia)"},
                {"Type": "TERM_MATCH", "Field": "usagetype", "Value": "KMS-Requests"},
            ]
        },
        "aws_nat_gateway": {
            "service": "AWSNATGateway",
            "filters": [
                {"Type": "TERM_MATCH", "Field": "location", "Value": "US East (N. Virginia)"},
                {"Type": "TERM_MATCH", "Field": "group", "Value": "NAT Gateway"},
            ]
        },
        # You can expand here for other known types
    }

    pricing_data = pricing_map.get(resource_type)
    if pricing_data:
        try:
            live_price = get_aws_pricing(
                pricing_data["service"],
                filters=pricing_data["filters"]
            )
            if live_price is not None:
                return round(float(live_price), 4)
            else:
                print(f"⚠️  No pricing found for {resource_type} ({name}), using fallback.")
        except Exception as e:
            print(f"❌ Error estimating cost for {resource_type} ({name}): {e}")
    else:
        print(f"ℹ️  No mapping found for {resource_type} ({name}), using default.")

    # Fallback if nothing matches
    return 0.5
