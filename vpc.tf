module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  for_each =  "${local.config.vpcs}"

  name = each.key
  cidr = each.value.vpc_cidr

  azs             = each.value.subnetworks.availability_zones
  private_subnets = each.value.subnetworks.private_subnets
  public_subnets  = each.value.subnetworks.public_subnets
}
