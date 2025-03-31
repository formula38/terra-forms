variable "name_prefix" {}
variable "log_bucket_name" {}
variable "kms_key_id" {}
variable "common_tags" {
  type = map(string)
  default = {}
}
