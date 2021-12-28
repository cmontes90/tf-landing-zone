locals {
  vpc_attachments_without_default_route_table_association = {
    for k, v in var.vpc_attachments : k => v if lookup(v, "transit_gateway_default_route_table_association", true) != true && lookup(v, "transit_gateway_main_route_table", true) == true
  }

  vpc_attachments_without_default_route_table_propagation = {
    for k, v in var.vpc_attachments : k => v if lookup(v, "transit_gateway_default_route_table_propagation", true) != true && lookup(v, "transit_gateway_main_route_table", true) == true
  }

  # List of maps with key and route values
  vpc_attachments_with_routes = chunklist(flatten([
    for k, v in var.vpc_attachments : setproduct([{ key = k }], v["tgw_routes"]) if length(lookup(v, "tgw_routes", {})) > 0
  ]), 2)

  vpc_attachments_with_routes_prod = chunklist(flatten([
    for k, v in var.vpc_attachments : setproduct([{ key = k }], v["tgw_routes_prod"]) if length(lookup(v, "tgw_routes", {})) > 0
  ]), 2)

    vpc_attachments_with_routes_non_prod = chunklist(flatten([
    for k, v in var.vpc_attachments : setproduct([{ key = k }], v["tgw_routes_non_prod"]) if length(lookup(v, "tgw_routes", {})) > 0
  ]), 2)

  tgw_default_route_table_tags_merged = merge(
    {
      "Name" = format("%s", var.name)
    },
    var.tags,
    var.tgw_default_route_table_tags,
  )

  vpc_route_table_destination_cidr = flatten([
    for k, v in var.vpc_attachments : [
      for rtb_id in lookup(v, "vpc_route_table_ids", []) : {
        rtb_id = rtb_id
        cidr   = v["tgw_destination_cidr"]
      }
    ]
  ])
}

resource "aws_ec2_transit_gateway" "this" {
  count = var.create_tgw ? 1 : 0

  description                     = coalesce(var.description, var.name)
  amazon_side_asn                 = var.amazon_side_asn
  default_route_table_association = var.enable_default_route_table_association ? "enable" : "disable"
  default_route_table_propagation = var.enable_default_route_table_propagation ? "enable" : "disable"
  auto_accept_shared_attachments  = var.enable_auto_accept_shared_attachments ? "enable" : "disable"
  vpn_ecmp_support                = var.enable_vpn_ecmp_support ? "enable" : "disable"
  dns_support                     = var.enable_dns_support ? "enable" : "disable"

  tags = merge(
    {
      "Name" = format("%s-tgw", var.name)
    },
    var.tags,
    var.tgw_tags,
  )
}

resource "aws_ec2_tag" "this" {
  for_each    = var.create_tgw && var.enable_default_route_table_association ? local.tgw_default_route_table_tags_merged : {}
  resource_id = aws_ec2_transit_gateway.this[0].association_default_route_table_id
  key         = each.key
  value       = each.value
}

#########################
# Route table and routes
#########################
resource "aws_ec2_transit_gateway_route_table" "this" {
  count = var.create_tgw ? 1 : 0

  transit_gateway_id = aws_ec2_transit_gateway.this[0].id

  tags = merge(
    {
      "Name" = format("%s-rt", "interconnect")
    },
    var.tags,
    var.tgw_route_table_tags,
  )
}


resource "aws_ec2_transit_gateway_route_table" "production" {
  count = var.create_tgw  && var.create_route_table_prod ? 1 : 0

  transit_gateway_id = aws_ec2_transit_gateway.this[0].id

  tags = merge(
    {
      "Name" = format("%s-rt", "production")
    },
    var.tags,
    var.tgw_route_table_tags,
  )
}

resource "aws_ec2_transit_gateway_route_table" "non_production" {
  count = var.create_tgw  && var.create_route_table_non_prod ? 1 : 0

  transit_gateway_id = aws_ec2_transit_gateway.this[0].id

  tags = merge(
    {
      "Name" = format("%s-rt", "non_production")
    },
    var.tags,
    var.tgw_route_table_tags,
  )
}

# VPC attachment routes

# resource "aws_ec2_transit_gateway_route" "this" {
#   count = var.create_tgw_route ? length(local.vpc_attachments_with_routes): 0

#   destination_cidr_block = local.vpc_attachments_with_routes[count.index][1]["destination_cidr_block"]
#   blackhole              = lookup(local.vpc_attachments_with_routes[count.index][1], "blackhole", null)

#   transit_gateway_route_table_id = var.create_tgw ? aws_ec2_transit_gateway_route_table.this[0].id : var.transit_gateway_route_table_id
#   transit_gateway_attachment_id  = tobool(lookup(local.vpc_attachments_with_routes[count.index][1], "blackhole", false)) == false ? aws_ec2_transit_gateway_vpc_attachment.this[local.vpc_attachments_with_routes[count.index][0]["key"]].id : null
# }
resource "aws_ec2_transit_gateway_route" "this" {
  count = var.create_tgw_route ? length(local.vpc_attachments_with_routes): 0

  destination_cidr_block = tostring(local.vpc_attachments_with_routes[count.index][1]["destination_cidr_block"])
  blackhole              = lookup(local.vpc_attachments_with_routes[count.index][1], "blackhole", null)

  transit_gateway_route_table_id = var.create_tgw ? aws_ec2_transit_gateway_route_table.this[0].id : lookup(local.vpc_attachments_with_routes[count.index][1], "transit_gateway_route_table_id", var.transit_gateway_route_table_id)
  transit_gateway_attachment_id  = tobool(lookup(local.vpc_attachments_with_routes[count.index][1], "blackhole", false)) == false ? lookup(local.vpc_attachments_with_routes[count.index][1], "transit_gateway_attachment_id", aws_ec2_transit_gateway_vpc_attachment.this[local.vpc_attachments_with_routes[count.index][0]["key"]].id) : null
}


resource "aws_ec2_transit_gateway_route" "production" {
  count = var.create_tgw_route_prod ? length(local.vpc_attachments_with_routes_prod): 0

  destination_cidr_block = local.vpc_attachments_with_routes_prod[count.index][1]["destination_cidr_block"]
  blackhole              = lookup(local.vpc_attachments_with_routes_prod[count.index][1], "blackhole", null)

  transit_gateway_route_table_id = var.create_tgw ? aws_ec2_transit_gateway_route_table.this[0].id : lookup(local.vpc_attachments_with_routes_prod[count.index][1], "transit_gateway_route_table_id", var.transit_gateway_route_table_prod_id)
  transit_gateway_attachment_id  = tobool(lookup(local.vpc_attachments_with_routes_prod[count.index][1], "blackhole", false)) == false ? lookup(local.vpc_attachments_with_routes_prod[count.index][1], "transit_gateway_attachment_id", aws_ec2_transit_gateway_vpc_attachment.this[local.vpc_attachments_with_routes[count.index][0]["key"]].id) : null
}


resource "aws_ec2_transit_gateway_route" "non_production" {
  count = var.create_tgw_route_non_prod ? length(local.vpc_attachments_with_routes_non_prod): 0

  destination_cidr_block = local.vpc_attachments_with_routes_non_prod[count.index][1]["destination_cidr_block"]
  blackhole              = lookup(local.vpc_attachments_with_routes_non_prod[count.index][1], "blackhole", null)

  transit_gateway_route_table_id = var.create_tgw ? aws_ec2_transit_gateway_route_table.this[0].id : lookup(local.vpc_attachments_with_routes_non_prod[count.index][1], "transit_gateway_route_table_id", var.transit_gateway_route_table_non_prod_id)
  transit_gateway_attachment_id  = tobool(lookup(local.vpc_attachments_with_routes_non_prod[count.index][1], "blackhole", false)) == false ? lookup(local.vpc_attachments_with_routes_non_prod[count.index][1], "transit_gateway_attachment_id", aws_ec2_transit_gateway_vpc_attachment.this[local.vpc_attachments_with_routes[count.index][0]["key"]].id) : null
}

resource "aws_route" "this" {
  for_each = { for x in local.vpc_route_table_destination_cidr : x.rtb_id => x.cidr }

  route_table_id         = each.key
  destination_cidr_block = each.value
  transit_gateway_id     = aws_ec2_transit_gateway.this[0].id
}

###########################################################
# VPC Attachments, route table association and propagation
###########################################################
resource "aws_ec2_transit_gateway_vpc_attachment" "this" {
  for_each = var.vpc_attachments

  transit_gateway_id = lookup(each.value, "tgw_id", var.create_tgw ? aws_ec2_transit_gateway.this[0].id : null)
  vpc_id             = each.value["vpc_id"]
  subnet_ids         = each.value["subnet_ids"]

  dns_support                                     = lookup(each.value, "dns_support", true) ? "enable" : "disable"
  ipv6_support                                    = lookup(each.value, "ipv6_support", false) ? "enable" : "disable"
  appliance_mode_support                          = lookup(each.value, "appliance_mode_support", false) ? "enable" : "disable"
  transit_gateway_default_route_table_association = lookup(each.value, "transit_gateway_default_route_table_association", true)
  transit_gateway_default_route_table_propagation = lookup(each.value, "transit_gateway_default_route_table_propagation", true)

  tags = merge(
    {
      Name = format("%s-%s", var.name, each.key)
    },
    var.tags,
    var.tgw_vpc_attachment_tags,
  )
}
###########################################################
# Production route table association and propagation
###########################################################

resource "aws_ec2_transit_gateway_route_table_association" "production" {
  count = var.create_route_table_prod ? length(var.route_table_prod_attachments) : 0

  # Create association if it was not set already by aws_ec2_transit_gateway_vpc_attachment resource
  transit_gateway_attachment_id  = var.route_table_prod_attachments[count.index]
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.production[0].id
}

resource "aws_ec2_transit_gateway_route_table_propagation" "production" {
  count = var.create_route_table_prod ? length(var.route_table_prod_attachments) : 0

  # Create association if it was not set already by aws_ec2_transit_gateway_vpc_attachment resource
  transit_gateway_attachment_id  = var.route_table_prod_attachments[count.index]
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.production[0].id
}

###########################################################
# Non-Production route table association and propagation
###########################################################

resource "aws_ec2_transit_gateway_route_table_association" "non_production" {
  count = var.create_route_table_non_prod ? length(var.route_table_non_prod_attachments) : 0

  # Create association if it was not set already by aws_ec2_transit_gateway_vpc_attachment resource
  transit_gateway_attachment_id  = var.route_table_non_prod_attachments[count.index]
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.non_production[0].id
}

resource "aws_ec2_transit_gateway_route_table_propagation" "non_production" {
  count = var.create_route_table_non_prod ? length(var.route_table_non_prod_attachments) : 0

  # Create association if it was not set already by aws_ec2_transit_gateway_vpc_attachment resource
  transit_gateway_attachment_id  = var.route_table_non_prod_attachments[count.index]
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.non_production[0].id
}

###########################################################
# Interconnect route table association and propagation
###########################################################
resource "aws_ec2_transit_gateway_route_table_association" "this" {
  for_each = local.vpc_attachments_without_default_route_table_association

  # Create association if it was not set already by aws_ec2_transit_gateway_vpc_attachment resource
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.this[each.key].id
  transit_gateway_route_table_id = var.transit_gateway_route_table_id
}

resource "aws_ec2_transit_gateway_route_table_propagation" "this" {
  for_each = local.vpc_attachments_without_default_route_table_propagation

  # Create association if it was not set already by aws_ec2_transit_gateway_vpc_attachment resource
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.this[each.key].id
  transit_gateway_route_table_id = var.transit_gateway_route_table_id
}

##########################
# Resource Access Manager
##########################
resource "aws_ram_resource_share" "this" {
  count = var.create_tgw && var.share_tgw ? 1 : 0

  name                      = coalesce(var.ram_name, var.name)
  allow_external_principals = var.ram_allow_external_principals

  tags = merge(
    {
      "Name" = format("%s", coalesce(var.ram_name, var.name))
    },
    var.tags,
    var.ram_tags,
  )
}

resource "aws_ram_resource_association" "this" {
  count = var.create_tgw && var.share_tgw ? 1 : 0

  resource_arn       = aws_ec2_transit_gateway.this[0].arn
  resource_share_arn = aws_ram_resource_share.this[0].id
}

resource "aws_ram_principal_association" "this" {
  count = var.create_tgw && var.share_tgw ? length(var.ram_principals) : 0

  principal          = var.ram_principals[count.index]
  resource_share_arn = aws_ram_resource_share.this[0].arn
}

resource "aws_ram_resource_share_accepter" "this" {
  count = !var.create_tgw && !var.share_with_organization && var.share_tgw ? 1 : 0

  share_arn = var.ram_resource_share_arn
}
