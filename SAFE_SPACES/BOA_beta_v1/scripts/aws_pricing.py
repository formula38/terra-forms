import boto3
import json

def get_price(service_code, usage_type_prefix=None, region='US East (N. Virginia)', product_family=None):
    client = boto3.client('pricing', region_name='us-east-1')  # Only region supported

    filters = [
        {'Type': 'TERM_MATCH', 'Field': 'serviceCode', 'Value': service_code},
        {'Type': 'TERM_MATCH', 'Field': 'location', 'Value': region}
    ]

    if usage_type_prefix:
        filters.append({'Type': 'TERM_MATCH', 'Field': 'usageType', 'Value': usage_type_prefix})

    if product_family:
        filters.append({'Type': 'TERM_MATCH', 'Field': 'productFamily', 'Value': product_family})

    response = client.get_products(ServiceCode=service_code, Filters=filters, MaxResults=1)

    if not response['PriceList']:
        return None

    price_item = json.loads(response['PriceList'][0])
    on_demand = next(iter(price_item['terms']['OnDemand'].values()))
    price_dimensions = next(iter(on_demand['priceDimensions'].values()))
    price_per_unit = price_dimensions['pricePerUnit']['USD']
    return float(price_per_unit)
