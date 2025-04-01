output "waf_acl_arn" {
  value = aws_wafv2_web_acl.cloudfront_acl.arn
}
