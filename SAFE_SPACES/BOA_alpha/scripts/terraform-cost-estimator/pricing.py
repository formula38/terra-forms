import boto3

def get_aws_pricing(service_code, filters, region="us-west-2"):
    client = boto3.client("pricing", region_name="us-east-1")  # Always use us-east-1 for the API

    response = client.get_products(
        ServiceCode=service_code,
        Filters=filters,
        FormatVersion="aws_v1",
        MaxResults=1
    )

    products = response.get("PriceList", [])
    if not products:
        return None

    product_json = eval(products[0])  # Safe with AWS pricing payloads
    price_dimensions = product_json["terms"]["OnDemand"]
    for term in price_dimensions.values():
        price_detail = next(iter(term["priceDimensions"].values()))
        price_per_unit = price_detail["pricePerUnit"]["USD"]
        return float(price_per_unit)

    return None

