variable "cloudfront_domain_aliases" {
  description = "A list of CNAMEs (aliases) to associate with the distribution."
  type        = list(string)
  default     = []
}

variable "cloudfront_waf_web_acl_id" {
  description = "The WAF Web ACL ID to associate with this distribution."
  type        = string
  default     = null
}

variable "cloudfront_acm_certificate_arn" {
  type        = string
  default     = null
}

variable "origin_bucket_name" {
  description = "The domain name of the S3 bucket origin (e.g., <bucket>.s3.amazonaws.com)"
  type        = string
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
}
