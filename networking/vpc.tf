module "vpc-interconnect" {
  source = "../modules/terraform-aws-vpc"

  name = "interconnect"
  cidr = "10.0.0.0/16"

  azs             = ["us-east-1a", "us-east-1b"]
  private_subnets = ["10.0.0.0/24", "10.0.2.0/24", "10.0.4.0/24", "10.0.6.0/24"]
  public_subnets  = ["10.0.1.0/24", "10.0.3.0/24", "10.0.5.0/24", "10.0.7.0/24"]
  intra_subnets   = ["10.0.10.0/24", "10.0.11.0/24"]

  enable_dns_hostnames = true
  enable_dns_support   = true

  enable_nat_gateway     = true
  one_nat_gateway_per_az = true

  # tgw_route        = true
  # internal_network = "10.0.0.0/8"
  # transit_gw_id    = module.tgw_us-east-1.ec2_transit_gateway_id


  tags = merge(
    {
      environment = "interconnect"
    },
    local.tags
  )

}


# module "vpc-production" {
#   source = "../modules/terraform-aws-vpc"

#   providers = {
#     aws = aws.prod
#   }

#   name = "production"
#   cidr = "10.1.0.0/16"

#   azs           = ["us-east-1a", "us-east-1b"]
#   intra_subnets = ["10.1.10.0/24", "10.1.11.0/24"]

#   enable_dns_hostnames = true
#   enable_dns_support   = true

#   create_igw = false

#   tgw_route     = true
#   transit_gw_id = module.tgw_us-east-1.ec2_transit_gateway_id

#   tags = merge(
#     {
#       environment = "production"
#     },
#     local.tags
#   )

# }


# module "vpc-development" {
#   source = "../modules/terraform-aws-vpc"

#   providers = {
#     aws = aws.dev
#   }

#   name = "development"
#   cidr = "10.2.0.0/16"

#   azs           = ["us-east-1a", "us-east-1b"]
#   intra_subnets = ["10.2.10.0/24", "10.2.11.0/24"]

#   enable_dns_hostnames = true
#   enable_dns_support   = true

#   create_igw = false

#   tgw_route     = true
#   transit_gw_id = module.tgw_us-east-1.ec2_transit_gateway_id

#   tags = merge(
#     {
#       environment = "development"
#     },
#     local.tags
#   )

# }
