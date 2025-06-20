variable "domain_name" {
  description = "The domain name to use for the hosted zone"
  type        = string
}

variable "use_existing_zone" {
  description = "Whether to use an existing Route 53 zone or create a new one"
  type        = bool
  default     = true
}
