data "aws_organizations_organization" "cmontes" {}


module "tgw_us-east-1" {
  source = "../modules/terraform-aws-transit-gateway"

  name            = "interconnect"
  description     = "My TGW shared with several other AWS accounts"
  amazon_side_asn = 64532

  share_tgw                              = true
  enable_auto_accept_shared_attachments  = true # When "true" there is no need for RAM resources if using multiple AWS accounts
  enable_default_route_table_association = false
  enable_default_route_table_propagation = false
  ram_allow_external_principals          = true
  ram_principals                         = [data.aws_organizations_organization.cmontes.arn]

  create_route_table_non_prod = true
  create_route_table_prod     = true

  #route_table_prod_attachments = module.tgw_peer_prod.ec2_transit_gateway_vpc_attachment_ids
  #route_table_non_prod_attachments = module.tgw_peer_dev.ec2_transit_gateway_vpc_attachment_ids

  tags = merge(
    {
      environment = "interconnect"
    },
    local.tags
  )

  tgw_tags = {
    Name = "${local.environment["inter"]}-us-east-1-tgw"
  }

}

module "tgw_interconnect" {
  source = "../modules/terraform-aws-transit-gateway"

  name            = "interconnect"
  description     = "My TGW shared with several other AWS accounts"
  amazon_side_asn = 64532

  share_tgw                               = true
  create_tgw                              = false
  create_tgw_route                        = true
  create_tgw_route_prod                   = true
  create_tgw_route_non_prod               = true

  transit_gateway_route_table_id          = module.tgw_us-east-1.ec2_transit_gateway_route_table_id
  transit_gateway_route_table_prod_id     = module.tgw_us-east-1.ec2_transit_gateway_route_table_prod_id
  transit_gateway_route_table_non_prod_id = module.tgw_us-east-1.ec2_transit_gateway_route_table_non_prod_id
 
  enable_auto_accept_shared_attachments   = true # When "true" there is no need for RAM resources if using multiple AWS accounts
  enable_default_route_table_association  = false
  enable_default_route_table_propagation  = false
  
  ram_allow_external_principals           = true
  ram_principals                          = [data.aws_organizations_organization.cmontes.arn]
  share_with_organization                 = true

  vpc_attachments = {
    vpc1 = {
      vpc_id     = module.vpc-interconnect.vpc_id        # module.vpc1.vpc_id
      subnet_ids = module.vpc-interconnect.intra_subnets # module.vpc1.private_subnets

      tgw_routes = [
        {
          destination_cidr_block = "10.0.0.0/16"
        },
        {
          destination_cidr_block = "10.1.0.0/16"
          transit_gateway_attachment_id = "tgw-attach-0d592f033d0f14605"
        },
        {
          destination_cidr_block = "10.2.0.0/16"
          transit_gateway_attachment_id = "tgw-attach-04c89b1b3ca17748a"
        }
      ]

      tgw_routes_prod = [
        {
          destination_cidr_block = "0.0.0.0/0"
        }
      ]

      tgw_routes_non_prod = [
        {
          destination_cidr_block = "0.0.0.0/0"
        },
        {
          blackhole              = true
          destination_cidr_block = "10.2.0.0/16"
        }
      ]
      tgw_id                                          = module.tgw_us-east-1.ec2_transit_gateway_id
      dns_support                                     = true
      ipv6_support                                    = false
      transit_gateway_default_route_table_association = false
      transit_gateway_default_route_table_propagation = false
    }
  }

  tags = merge(
    {
      environment = "interconnect"
    },
    local.tags
  )

  tgw_tags = {
    Name = "${local.environment["inter"]}-us-east-1-tgw"
  }

}

module "tgw_peer_prod" {
  source = "../modules/terraform-aws-transit-gateway"

  providers = {
    aws = aws.prod
  }

  name = "production"

  share_tgw  = false
  create_tgw = false

  vpc_attachments = {
    vpc1 = {
      vpc_id                                          = module.vpc-production.vpc_id        # module.vpc1.vpc_id
      subnet_ids                                      = module.vpc-production.intra_subnets # module.vpc1.private_subnets
      tgw_id                                          = module.tgw_us-east-1.ec2_transit_gateway_id
      dns_support                                     = true
      ipv6_support                                    = false
      transit_gateway_default_route_table_propagation = false
      transit_gateway_default_route_table_association = false
      transit_gateway_main_route_table                = false
    }

  }

  tags = merge(
    {
      environment = "production"
    },
    local.tags
  )

}

module "tgw_peer_dev" {
  source = "../modules/terraform-aws-transit-gateway"

  providers = {
    aws = aws.dev
  }

  name = "development"

  share_tgw  = false
  create_tgw = false

  vpc_attachments = {
    vpc1 = {
      vpc_id                                          = module.vpc-development.vpc_id        # module.vpc1.vpc_id
      subnet_ids                                      = module.vpc-development.intra_subnets # module.vpc1.private_subnets
      tgw_id                                          = module.tgw_us-east-1.ec2_transit_gateway_id
      dns_support                                     = true
      ipv6_support                                    = false
      transit_gateway_default_route_table_propagation = false
      transit_gateway_default_route_table_association = false
      transit_gateway_main_route_table                = false
    }

  }

  tags = merge(
    {
      environment = "development"
    },
    local.tags
  )

}
