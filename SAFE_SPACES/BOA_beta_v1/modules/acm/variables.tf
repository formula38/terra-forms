variable "domain_name" {
  type        = string
  description = "Primary domain name for ACM certificate"
}

variable "subject_alternative_names" {
  type        = list(string)
  description = "Alternative domain names for the certificate"
  default     = []
}
variable "route53_zone_id" {}
variable "common_tags" {
  type = map(string)
}
