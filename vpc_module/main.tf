locals {
  len_public_subnets   = max(length(var.public_subnets))
  len_private_subnets  = max(length(var.private_subnets))
  len_database_subnets = max(length(var.database_subnets))

  max_subnet_length = max(
    local.len_private_subnets,
    local.len_public_subnets,
    local.len_database_subnets,

  )

  # Use `local.vpc_id` to give a hint to Terraform that subnets should be deleted before secondary CIDR blocks can be free!
  vpc_id = try(aws_vpc.this[0].id, "")

  create_vpc = var.create_vpc
}

################################################################################
# VPC
################################################################################

resource "aws_vpc" "this" {
  count = local.create_vpc ? 1 : 0

  cidr_block = var.use_ipam_pool ? null : var.cidr

  enable_dns_hostnames = var.enable_dns_hostnames
  enable_dns_support   = var.enable_dns_support

  tags = merge(
    { "Name" = var.name },
    var.tags,
    var.vpc_tags,
  )
}

################################################################################
# DHCP Options Set
################################################################################

################################################################################
# Publiс Subnets
################################################################################

locals {
  create_public_subnets = local.create_vpc && local.len_public_subnets > 0
}

resource "aws_subnet" "public" {

  availability_zone    = var.azs
  availability_zone_id = var.azs
  cidr_block           = var.public_subnets

  vpc_id = local.vpc_id

  tags = var.public_subnet_tags
}

resource "aws_route_table" "public" {
  count = local.create_public_subnets ? 1 : 0

  vpc_id = local.vpc_id

  tags = {
    Name = var.name


  }
}

resource "aws_route_table_association" "public" {
  count = local.create_public_subnets ? local.len_public_subnets : 0

  subnet_id      = element(aws_subnet.public[*].id, count.index)
  route_table_id = aws_route_table.public[0].id
}

resource "aws_route" "public_internet_gateway" {
  count = local.create_public_subnets && var.create_igw ? 1 : 0

  route_table_id         = aws_route_table.public[0].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this[0].id

  timeouts {
    create = "5m"
  }
}
################################################################################
# Public Network ACLs
################################################################################

resource "aws_network_acl" "public" {
  count = local.create_public_subnets && var.public_dedicated_network_acl ? 1 : 0

  vpc_id     = local.vpc_id
  subnet_ids = aws_subnet.public[*].id

  tags = merge(
    { "Name" = "${var.name}-${var.public_subnet_suffix}" },
    var.tags,
    var.public_acl_tags,
  )
}

resource "aws_network_acl_rule" "public_inbound" {
  count = local.create_public_subnets && var.public_dedicated_network_acl ? length(var.public_inbound_acl_rules) : 0

  network_acl_id = aws_network_acl.public[0].id

  egress      = false
  rule_number = var.public_inbound_acl_rules[count.index]["rule_number"]
  rule_action = var.public_inbound_acl_rules[count.index]["rule_action"]
  from_port   = lookup(var.public_inbound_acl_rules[count.index], "from_port", null)
  to_port     = lookup(var.public_inbound_acl_rules[count.index], "to_port", null)
  icmp_code   = lookup(var.public_inbound_acl_rules[count.index], "icmp_code", null)
  icmp_type   = lookup(var.public_inbound_acl_rules[count.index], "icmp_type", null)
  protocol    = var.public_inbound_acl_rules[count.index]["protocol"]
  cidr_block  = lookup(var.public_inbound_acl_rules[count.index], "cidr_block", null)

}

resource "aws_network_acl_rule" "public_outbound" {
  count = local.create_public_subnets && var.public_dedicated_network_acl ? length(var.public_outbound_acl_rules) : 0

  network_acl_id = aws_network_acl.public[0].id

  egress      = true
  rule_number = var.public_outbound_acl_rules[count.index]["rule_number"]
  rule_action = var.public_outbound_acl_rules[count.index]["rule_action"]
  from_port   = lookup(var.public_outbound_acl_rules[count.index], "from_port", null)
  to_port     = lookup(var.public_outbound_acl_rules[count.index], "to_port", null)
  icmp_code   = lookup(var.public_outbound_acl_rules[count.index], "icmp_code", null)
  icmp_type   = lookup(var.public_outbound_acl_rules[count.index], "icmp_type", null)
  protocol    = var.public_outbound_acl_rules[count.index]["protocol"]
  cidr_block  = lookup(var.public_outbound_acl_rules[count.index], "cidr_block", null)
}

################################################################################
# Private Subnets
################################################################################

locals {
  create_private_subnets = local.create_vpc && local.len_private_subnets > 0
}

resource "aws_subnet" "private" {
  count = local.create_private_subnets ? local.len_private_subnets : 0

  cidr_block = var.private_subnets
  vpc_id     = local.vpc_id

  tags = {
    Name = var.private_subnet_names
  }
}

# There are as many routing tables as the number of NAT gateways
resource "aws_route_table" "private" {
  count = local.create_private_subnets && local.max_subnet_length > 0 ? local.nat_gateway_count : 0

  vpc_id = local.vpc_id
}


resource "aws_route_table_association" "private" {
  count = local.create_private_subnets ? local.len_private_subnets : 0

  subnet_id = element(aws_subnet.private[*].id, count.index)
  route_table_id = element(
    aws_route_table.private[*].id,
    var.single_nat_gateway ? 0 : count.index,
  )
}

################################################################################
# Private Network ACLs
################################################################################

locals {
  create_private_network_acl = local.create_private_subnets && var.private_dedicated_network_acl
}

resource "aws_network_acl" "private" {
  count = local.create_private_network_acl ? 1 : 0

  vpc_id     = local.vpc_id
  subnet_ids = aws_subnet.private[*].id

  tags = {
    name = var.private_acl_tags
  }
}

resource "aws_network_acl_rule" "private_inbound" {
  count = local.create_private_network_acl ? length(var.private_inbound_acl_rules) : 0

  network_acl_id = aws_network_acl.private[0].id

  egress      = false
  rule_number = var.private_inbound_acl_rules[count.index]["rule_number"]
  rule_action = var.private_inbound_acl_rules[count.index]["rule_action"]
  from_port   = lookup(var.private_inbound_acl_rules[count.index], "from_port", null)
  to_port     = lookup(var.private_inbound_acl_rules[count.index], "to_port", null)
  icmp_code   = lookup(var.private_inbound_acl_rules[count.index], "icmp_code", null)
  icmp_type   = lookup(var.private_inbound_acl_rules[count.index], "icmp_type", null)
  protocol    = var.private_inbound_acl_rules[count.index]["protocol"]
  cidr_block  = lookup(var.private_inbound_acl_rules[count.index], "cidr_block", null)
}

resource "aws_network_acl_rule" "private_outbound" {
  count = local.create_private_network_acl ? length(var.private_outbound_acl_rules) : 0

  network_acl_id = aws_network_acl.private[0].id

  egress      = true
  rule_number = var.private_outbound_acl_rules[count.index]["rule_number"]
  rule_action = var.private_outbound_acl_rules[count.index]["rule_action"]
  from_port   = lookup(var.private_outbound_acl_rules[count.index], "from_port", null)
  to_port     = lookup(var.private_outbound_acl_rules[count.index], "to_port", null)
  icmp_code   = lookup(var.private_outbound_acl_rules[count.index], "icmp_code", null)
  icmp_type   = lookup(var.private_outbound_acl_rules[count.index], "icmp_type", null)
  protocol    = var.private_outbound_acl_rules[count.index]["protocol"]
  cidr_block  = lookup(var.private_outbound_acl_rules[count.index], "cidr_block", null)
}

################################################################################
# Database Subnets
################################################################################


################################################################################
# Internet Gateway
################################################################################

resource "aws_internet_gateway" "this" {
  count = local.create_public_subnets && var.create_igw ? 1 : 0

  vpc_id = local.vpc_id

  tags = merge(
    { "Name" = var.name },
    var.tags,
    var.igw_tags,
  )
}

resource "aws_egress_only_internet_gateway" "this" {
  count = local.create_vpc && var.create_egress_only_igw && var.enable_ipv6 && local.max_subnet_length > 0 ? 1 : 0

  vpc_id = local.vpc_id

  tags = merge(
    { "Name" = var.name },
    var.tags,
    var.igw_tags,
  )
}

################################################################################
# NAT Gateway
################################################################################

locals {
  nat_gateway_count = var.single_nat_gateway ? 1 : 0
  nat_gateway_ips   = var.reuse_nat_ips ? var.external_nat_ip_ids : try(aws_eip.nat[*].id, [])
}

resource "aws_eip" "nat" {
  count = local.create_vpc && var.enable_nat_gateway && !var.reuse_nat_ips ? local.nat_gateway_count : 0

  domain = "vpc"

  tags = merge(
    {
      "Name" = format(
        "${var.name}-%s",
        element(var.azs, var.single_nat_gateway ? 0 : count.index),
      )
    },
    var.tags,
    var.nat_eip_tags,
  )

  depends_on = [aws_internet_gateway.this]
}

resource "aws_nat_gateway" "this" {
  count = local.create_vpc && var.enable_nat_gateway ? local.nat_gateway_count : 0

  allocation_id = element(
    local.nat_gateway_ips,
    var.single_nat_gateway ? 0 : count.index,
  )
  subnet_id = element(
    aws_subnet.public[*].id,
    var.single_nat_gateway ? 0 : count.index,
  )

  tags = merge(
    {
      "Name" = format(
        "${var.name}-%s",
        element(var.azs, var.single_nat_gateway ? 0 : count.index),
      )
    },
    var.tags,
    var.nat_gateway_tags,
  )

  depends_on = [aws_internet_gateway.this]
}

resource "aws_route" "private_nat_gateway" {
  count = local.create_vpc && var.enable_nat_gateway ? local.nat_gateway_count : 0

  route_table_id         = element(aws_route_table.private[*].id, count.index)
  destination_cidr_block = var.nat_gateway_destination_cidr_block
  nat_gateway_id         = element(aws_nat_gateway.this[*].id, count.index)

  timeouts {
    create = "5m"
  }
}

################################################################################
# Customer Gateways
################################################################################


################################################################################
# VPN Gateway
################################################################################


################################################################################
# Default Network ACLs
################################################################################
