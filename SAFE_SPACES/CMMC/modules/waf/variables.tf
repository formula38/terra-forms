variable "common_tags" {
  type = map(string)
}

variable "managed_rule_groups" {
  description = "List of AWS managed rule groups to attach"
  type = list(object({
    name        = string
    vendor_name = string
    priority    = number
  }))
  default = [
    {
      name        = "AWSManagedRulesCommonRuleSet"
      vendor_name = "AWS"
      priority    = 1
    }
  ]
}