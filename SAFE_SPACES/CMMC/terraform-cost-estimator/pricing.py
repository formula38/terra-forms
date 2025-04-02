import boto3

def get_aws_pricing(service_code, usage_type=None, filters=[]):
    client = boto3.client("pricing", region_name="us-east-1")

    try:
        response = client.get_products(
            ServiceCode=service_code,
            Filters=filters,
            FormatVersion="aws_v1",
            MaxResults=1
        )

        if not response["PriceList"]:
            return None

        price_item = eval(response["PriceList"][0])
        terms = price_item.get("terms", {}).get("OnDemand", {})
        for term in terms.values():
            price_dimensions = term.get("priceDimensions", {})
            for dimension in price_dimensions.values():
                price_per_unit = dimension["pricePerUnit"].get("USD")
                return float(price_per_unit) if price_per_unit else None
    except Exception as e:
        print(f"❌ Pricing error: {e}")
        return None
