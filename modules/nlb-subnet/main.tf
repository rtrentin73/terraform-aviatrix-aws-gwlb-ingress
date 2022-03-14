# Create NLB subnet
resource "aws_subnet" "nlb_subnets" {
  count             = var.availability_zones_count
  vpc_id            = var.vpc_id
  cidr_block        = cidrsubnet(var.vpc_cidr, var.newbits, (count.index + var.availability_zones_count ))
  availability_zone = var.aws_availability_zone_names[count.index]
  tags = {
    az_index = count.index
    Name = "${var.vpc_name}-nlb-subnet-${count.index + 1}-${var.aws_availability_zone_names[count.index]}"
  }
}

## Create route tables for NLB subnets
resource "aws_route_table" "nlb_route_tables" {
  count             = var.availability_zones_count
  vpc_id            = var.vpc_id
  route {
    cidr_block = "0.0.0.0/0"
    vpc_endpoint_id = var.gwlbe[count.index]
  }

  lifecycle {
    ignore_changes = [route]
  }

  tags = {
    az_index = count.index
    Name = "${var.vpc_name}-nlb-subnet-${count.index + 1}-${var.aws_availability_zone_names[count.index]}"
  }
}

## Create route table association for NLB subnets
resource "aws_route_table_association" "nlb_route_table_association" {
  count          = var.availability_zones_count
  subnet_id      = aws_subnet.nlb_subnets[count.index].id
  route_table_id = aws_route_table.nlb_route_tables[count.index].id 
}

output "nlb_subnets" {
  value = {
    for nlb_subnet in aws_subnet.nlb_subnets:
    nlb_subnet.tags.az_index => {
      cidr_block = nlb_subnet.cidr_block
      subnet_id = nlb_subnet.id
    }
  }
}

