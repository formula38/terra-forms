##############################################
# modules/networking/main.tf
##############################################

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(
    {
      Name        = var.vpc_name
      Environment = var.environment
    },
    var.common_tags
  )
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = merge(
    {
      Name        = "${var.vpc_name}-igw"
      Environment = var.environment
    },
    var.common_tags
  )
}

resource "aws_subnet" "subnet_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.subnet_cidr_a
  availability_zone = var.availability_zone_a

  tags = merge(
    {
      Name        = "${var.vpc_name}-subnet-a"
      Environment = var.environment
    },
    var.common_tags
  )
}

resource "aws_subnet" "subnet_b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.subnet_cidr_b
  availability_zone = var.availability_zone_b

  tags = merge(
    {
      Name        = "${var.vpc_name}-subnet-b"
      Environment = var.environment
    },
    var.common_tags
  )
}

resource "aws_route_table" "rt" {
  vpc_id = aws_vpc.main.id

  dynamic "route" {
    for_each = var.enable_igw_route ? [1] : []
    content {
      cidr_block = var.route_cidr_block
      gateway_id = aws_internet_gateway.igw.id
    }
  }

  tags = merge(
    {
      Name        = "${var.vpc_name}-rt"
      Environment = var.environment
    },
    var.common_tags
  )
}

resource "aws_route_table_association" "rta_a" {
  subnet_id      = aws_subnet.subnet_a.id
  route_table_id = aws_route_table.rt.id
}

resource "aws_route_table_association" "rta_b" {
  subnet_id      = aws_subnet.subnet_b.id
  route_table_id = aws_route_table.rt.id
}

resource "aws_security_group" "main_sg" {
  name        = "${var.vpc_name}-sg"
  description = "Main security group"
  vpc_id      = aws_vpc.main.id

  dynamic "ingress" {
    for_each = var.security_group_ingress_rules
    content {
      description      = ingress.value.description
      from_port        = ingress.value.from_port
      to_port          = ingress.value.to_port
      protocol         = ingress.value.protocol
      cidr_blocks      = lookup(ingress.value, "cidr_blocks", [])
      ipv6_cidr_blocks = lookup(ingress.value, "ipv6_cidr_blocks", [])
      security_groups  = lookup(ingress.value, "security_groups", [])
    }
  }

  dynamic "egress" {
    for_each = var.security_group_egress_rules
    content {
      description      = egress.value.description
      from_port        = egress.value.from_port
      to_port          = egress.value.to_port
      protocol         = egress.value.protocol
      cidr_blocks      = lookup(egress.value, "cidr_blocks", [])
      ipv6_cidr_blocks = lookup(egress.value, "ipv6_cidr_blocks", [])
      security_groups  = lookup(egress.value, "security_groups", [])
    }
  }

  tags = merge(
    {
      Name        = "${var.vpc_name}-sg"
      Environment = var.environment
    },
    var.common_tags
  )
}

