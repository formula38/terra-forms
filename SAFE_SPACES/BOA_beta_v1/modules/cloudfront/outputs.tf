output "cloudfront_distribution_domain" {
  description = "CloudFront distribution domain name"
  value       = aws_cloudfront_distribution.secure_distribution.domain_name
}

output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID"
  value       = aws_cloudfront_distribution.secure_distribution.id
}

output "cloudfront_distribution_arn" {
  description = "CloudFront distribution ARN"
  value       = aws_cloudfront_distribution.secure_distribution.arn
}

output "cloudfront_oai_id" {
  value = aws_cloudfront_origin_access_identity.oai.id
}

output "cloudfront_oai_path" {
  value = aws_cloudfront_origin_access_identity.oai.cloudfront_access_identity_path
}
