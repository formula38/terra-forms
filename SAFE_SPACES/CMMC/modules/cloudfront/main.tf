resource "aws_cloudfront_distribution" "secure_distribution" {
  enabled             = true
  is_ipv6_enabled     = true
  comment             = "CMMC-secure CloudFront distribution"
  default_root_object = "index.html"

  aliases             = var.cloudfront_domain_aliases
  web_acl_id          = var.cloudfront_waf_web_acl_id

  origin {
    domain_name = var.origin_bucket_name
    origin_id   = "s3-origin"

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.oai.cloudfront_access_identity_path
    }
  }

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "s3-origin"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  viewer_certificate {
    acm_certificate_arn      = var.cloudfront_acm_certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  tags = var.common_tags
}

resource "aws_cloudfront_origin_access_identity" "oai" {
  comment = "OAI for ${var.common_tags["Name"]}-cloudfront"
}
