locals {
  region = "ap-south-1"
}
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "3.14.4"

  name = var.env_code
  cidr = var.vpc_cidr_block

  public_subnets  = var.public_cidr
  private_subnets = var.private_cidr
  azs             = ["${local.region}a", "${local.region}b"]

  enable_ipv6        = false
  enable_nat_gateway = true

  public_subnet_tags = {
    Name = "${var.env_code}-public"
  }


  tags = {
    Owner       = "user"
    Environment = "dev"
  }

  vpc_tags = {
    Name = "vpc-name"
  }

}
