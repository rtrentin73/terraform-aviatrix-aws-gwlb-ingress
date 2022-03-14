module "gwlbe_ingress_spoke_app_subnets" {
  source                      = "./modules/gwlbe-ingress-spoke-local-app-subnets"
  availability_zones_count    = var.availability_zones_count
  vpc_id                      = aws_vpc.ingress.id
  vpc_cidr                    = var.vpc_cidr
  newbits                     = local.newbits
  aws_availability_zone_names = data.aws_availability_zones.available.names
  vpc_name                    = var.vpc_name
  gateway_id                  = aws_internet_gateway.igw.id
  max_netnum                  = local.max_netnum
}

module "gwlbe_ingress_spoke_instance" {
  source    = "./modules/aws-linux-vm-public"
  count     = var.availability_zones_count
  vm_name   = "gwlbe-ingress-spoke-instance-${count.index+1}"
  vpc_id    = aws_vpc.ingress.id
  subnet_id = module.gwlbe_ingress_spoke_app_subnets.subnets[count.index].subnet_id
  key_name  = var.key_pair_name
}


