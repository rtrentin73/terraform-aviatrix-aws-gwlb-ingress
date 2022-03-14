module "transit_firenet_egress" {
  source  = "terraform-aviatrix-modules/aws-transit-firenet/aviatrix"
  version = "5.0.0"
  name = "egress"
  cidr           = "10.1.0.0/20"
  region         = var.region
  account        = var.account
  firewall_image = "Palo Alto Networks VM-Series Next-Generation Firewall (BYOL)"
  inspection_enabled = false
  egress_enabled = true
  enable_egress_transit_firenet = true
  single_az_ha = false
  use_gwlb = true
  tags = var.tags
  fw_tags = var.tags
}

module "transit_firenet_east_west" {
  source  = "terraform-aviatrix-modules/aws-transit-firenet/aviatrix"
  version = "5.0.0"
  name = "eastwest"
  cidr           = "10.2.0.0/20"
  region         = var.region
  account        = var.account
  firewall_image = "Palo Alto Networks VM-Series Next-Generation Firewall (BYOL)"
  inspection_enabled = true
  egress_enabled = false
  enable_egress_transit_firenet = false
  single_az_ha = false
  use_gwlb = true
  tags = var.tags
  fw_tags = var.tags
}

module "east_west_ingress_spoke" {
  source  = "terraform-aviatrix-modules/mc-spoke/aviatrix"
  version = "1.1.0"
  vpc_id = aws_vpc.ingress.id
  use_existing_vpc = true
  gw_subnet = module.avx_spoke_gw_subnets.gw_subnets[0].subnet_cidr
  hagw_subnet = module.avx_spoke_gw_subnets.gw_subnets[1].subnet_cidr
  region         = var.region
  account        = var.account
  cloud = "AWS"
  name = "east-west-ingress-spoke-gw"
  transit_gw = module.transit_firenet_east_west.transit_gateway.gw_name
  transit_gw_egress = module.transit_firenet_egress.transit_gateway.gw_name
  tags = var.tags
  depends_on = [
    module.gwlbe_ingress_spoke_instance,
    module.nlb_subnets
  ]
}

module "app_spoke" {
  source  = "terraform-aviatrix-modules/mc-spoke/aviatrix"
  version = "1.1.0"
  region         = var.region
  account        = var.account
  cloud = "AWS"
  name = "app-spoke-gw"
  transit_gw = module.transit_firenet_east_west.transit_gateway.gw_name
  transit_gw_egress = module.transit_firenet_egress.transit_gateway.gw_name
  cidr            = "10.200.0.0/24"
  tags = var.tags
}



# Obtain GWLB VPC endpoint Service Name from Firewall ENI by Bash + AWS CLI
module "shell_execute" {
  source  = "github.com/matti/terraform-shell-resource"
  command = "./get_vpce_service_name_from_fw_lan.sh ${module.transit_firenet_egress.aviatrix_firewall_instance[0].lan_interface} ${var.region}"
}
