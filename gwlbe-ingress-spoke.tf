


# Create a VPC
resource "aws_vpc" "ingress" {
  cidr_block = var.vpc_cidr
  tags = {
    "Name" = "${var.vpc_name}-vpc"
  }
}

# Create internet gateway and associate with VPC
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.ingress.id

  tags = {
    Name = "${var.vpc_name}-igw"
  }
}

# Retrive avaiability zones
data "aws_availability_zones" "available" {}

module "avx_spoke_gw_subnets" {
  source = "./modules/avx-spoke-gw-subnet"
  availability_zones_count = var.availability_zones_count
  vpc_id = aws_vpc.ingress.id
  vpc_cidr = var.vpc_cidr
  newbits = local.newbits
  aws_availability_zone_names = data.aws_availability_zones.available.names
  vpc_name = var.vpc_name
  gateway_id = aws_internet_gateway.igw.id
  max_netnum = local.max_netnum
}

# Create GWLB endpoint route table, only need one for entire VPC as they all point 0/0 to IGW
resource "aws_route_table" "gwlbe_route_table" {
  vpc_id            = aws_vpc.ingress.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  lifecycle {
    ignore_changes = [route]
  }
  tags = {
    Name = "${var.vpc_name}-gwlbe-subnets"
  }
}

# Create GWLB endpoint subnet, route table, route table association and GWLB endpoints
module "gwlbe" {
  source = "./modules/gwlbe-subnet"
  availability_zones_count = var.availability_zones_count
  vpc_id = aws_vpc.ingress.id
  vpc_cidr = var.vpc_cidr
  newbits = local.newbits
  aws_availability_zone_names = data.aws_availability_zones.available.names
  vpc_name = var.vpc_name
  route_table_id = aws_route_table.gwlbe_route_table.id
  gwlb_endpoint_service_name = module.shell_execute.stdout
}


# Create NLB subnet, route table, route table association
module "nlb_subnets" {
  source = "./modules/nlb-subnet"
  availability_zones_count = var.availability_zones_count
  vpc_id = aws_vpc.ingress.id
  vpc_cidr = var.vpc_cidr
  newbits = local.newbits
  aws_availability_zone_names = data.aws_availability_zones.available.names
  vpc_name = var.vpc_name
  gwlbe = module.gwlbe.gwlbe
}


# Create route tables for IGW edge, associate NLB subnet CIDR with GWLB endpoint in corresponding AZ
resource "aws_route_table" "igw_route_table" {
  vpc_id            = aws_vpc.ingress.id
  dynamic "route" {
    for_each = module.nlb_subnets.nlb_subnets
    content {
      cidr_block = route.value.cidr_block
      vpc_endpoint_id = module.gwlbe.gwlbe[route.key]
    }
  }

  tags = {
    Name = "${var.vpc_name}-igw-edge-route-table"
  }
  depends_on = [
    module.nlb_subnets
  ]
}

# Associate IGW edge route to IGW
resource "aws_route_table_association" "igw_edge_association" {
  gateway_id      = aws_internet_gateway.igw.id
  route_table_id = aws_route_table.igw_route_table.id
}

