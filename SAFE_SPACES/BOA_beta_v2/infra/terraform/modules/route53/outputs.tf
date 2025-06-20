output "zone_id" {
  value = var.use_existing_zone ? data.aws_route53_zone.selected[0].zone_id : aws_route53_zone.new_zone[0].zone_id
}

output "zone_name" {
  value = var.domain_name
}
