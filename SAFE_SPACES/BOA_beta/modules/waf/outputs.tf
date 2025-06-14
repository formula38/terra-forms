output "waf_acl_arn" {
  value = aws_wafv2_web_acl.cloudfront_acl.arn
}

output "cloudfront_waf_web_acl_id" {
  value = aws_wafv2_web_acl.cloudfront_acl.id
}
