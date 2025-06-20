import logging
from pricing import get_aws_pricing

logger = logging.getLogger("botocore")
logger.setLevel(logging.INFO)

# Automatically detect and estimate cost based on resource configuration
def estimate_cost(resource):
    resource_type = resource.get("type")
    name = resource.get("name")
    values = resource.get("change", {}).get("after", {})

    region = detect_region(values)
    logger.info(f"Estimating cost for {resource_type} ({name}) in region: {region}")

    if resource_type == "aws_instance":
        instance_type = values.get("instance_type", "t3.micro")
        return get_aws_pricing(
            "AmazonEC2",
            filters=[
                {"Type": "TERM_MATCH", "Field": "instanceType", "Value": instance_type},
                {"Type": "TERM_MATCH", "Field": "operatingSystem", "Value": "Linux"},
                {"Type": "TERM_MATCH", "Field": "location", "Value": region_to_full(region)},
                {"Type": "TERM_MATCH", "Field": "tenancy", "Value": "Shared"},
                {"Type": "TERM_MATCH", "Field": "capacitystatus", "Value": "Used"},
                {"Type": "TERM_MATCH", "Field": "preInstalledSw", "Value": "NA"},
            ],
        )

    if resource_type == "aws_s3_bucket":
        storage_class = values.get("storage_class", "Standard")
        return get_aws_pricing(
            "AmazonS3",
            region=region,
            filters=[
                {"Type": "TERM_MATCH", "Field": "storageClass", "Value": storage_class},
                {"Type": "TERM_MATCH", "Field": "locationType", "Value": "AWS Region"},
                {"Type": "TERM_MATCH", "Field": "productFamily", "Value": "Storage"},
            ],
        )

    if resource_type == "aws_db_instance":
        instance_class = values.get("instance_class", "db.t3.micro")
        engine = values.get("engine", "postgres")
        return get_aws_pricing(
            "AmazonRDS",
            region=region,
            filters=[
                {"Type": "TERM_MATCH", "Field": "instanceType", "Value": instance_class},
                {"Type": "TERM_MATCH", "Field": "databaseEngine", "Value": engine},
                {"Type": "TERM_MATCH", "Field": "deploymentOption", "Value": "Single-AZ"},
            ],
        )

    # Extendable: add more resource types here

    logger.info(f"ℹ️  No mapping found for {resource_type} ({name}), using default.")
    return 0.5


# Helper to detect AWS region from resource config
def detect_region(values):
    # Try known region sources in the plan structure
    if "region" in values:
        return values["region"]
    if "availability_zone" in values:
        # Convert "us-west-2a" -> "us-west-2"
        return values["availability_zone"][:-1]
    return "us-west-2"  # default fallback region

# Region code (us-west-2) → Full region name (US West (Oregon))
def region_to_full(region):
    mapping = {
        "us-east-1": "US East (N. Virginia)",
        "us-east-2": "US East (Ohio)",
        "us-west-1": "US West (N. California)",
        "us-west-2": "US West (Oregon)",
        "eu-west-1": "EU (Ireland)",
        "eu-central-1": "EU (Frankfurt)",
        "eu-west-2": "EU (London)",
        "eu-north-1": "EU (Stockholm)",
        # Add more as needed
    }
    return mapping.get(region, "US West (Oregon)")  # Default fallback

