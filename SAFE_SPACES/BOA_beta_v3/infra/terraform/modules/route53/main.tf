# Look up existing zone if flag is true
data "aws_route53_zone" "selected" {
  count        = var.use_existing_zone ? 1 : 0
  name         = var.domain_name
  private_zone = false
}

# Create new zone if flag is false
resource "aws_route53_zone" "new_zone" {
  count = var.use_existing_zone ? 0 : 1
  name  = var.domain_name

  tags = {
    Name = "${var.domain_name}-zone"
  }
}
