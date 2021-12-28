
locals {
  zone_vpc_authorization = chunklist(flatten([
    for k, v in var.zones : setproduct([{ key = k }], v["vpc_on_different_accounts"]) if length(lookup(v, "vpc_on_different_accounts", {})) > 0
  ]), 2)
}

resource "aws_route53_zone" "this" {
  for_each = var.create_zone ? var.zones : tomap({})

  name          = lookup(each.value, "domain_name", each.key)
  comment       = lookup(each.value, "comment", null)
  force_destroy = lookup(each.value, "force_destroy", false)

  dynamic "vpc" {
    for_each = try(tolist(lookup(each.value, "vpc", [])), [lookup(each.value, "vpc", {})])

    content {
      vpc_id     = vpc.value.vpc_id
      vpc_region = lookup(vpc.value, "vpc_region", null)
    }
  }

  tags = merge(
    lookup(each.value, "tags", {}),
    var.tags
  )

  lifecycle {
    ignore_changes = [vpc]
  }
}

resource "aws_route53_vpc_association_authorization" "this" {
  count = var.create_vpc_association_authorization ? length(local.zone_vpc_authorization) : 0

  vpc_id  = local.zone_vpc_authorization[count.index][1]["vpc_id"]
  zone_id = lookup(local.zone_vpc_authorization[count.index][1], "zone_id", aws_route53_zone.this[local.zone_vpc_authorization[count.index][0]["key"]].id)

}


resource "aws_route53_zone_association" "this" {
  provider = aws.dev

  count = var.create_vpc_association ? length(var.vpc_associations) : 0

  vpc_id  = element(concat(var.vpc_associations, [""]), count.index)
  zone_id = var.route53_zone_id
}