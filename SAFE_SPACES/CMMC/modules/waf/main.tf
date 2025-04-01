resource "aws_wafv2_web_acl" "cloudfront_acl" {
  name        = "cloudfront-waf-acl"
  description = "WAF for CloudFront distribution"
  scope       = "CLOUDFRONT"
  default_action {
    allow {}
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "cloudfront-waf"
    sampled_requests_enabled   = true
  }

  dynamic "rule" {
  for_each = var.managed_rule_groups
  content {
    name     = rule.value.name
    priority = rule.value.priority

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = rule.value.name
        vendor_name = rule.value.vendor_name
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = rule.value.name
      sampled_requests_enabled   = true
    }
  }
}

  tags = var.common_tags
}
