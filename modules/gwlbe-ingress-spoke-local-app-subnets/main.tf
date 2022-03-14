## Create subnets for Aviatrix Spoke Gateways
resource "aws_subnet" "subnets" {
  count             = var.availability_zones_count
  vpc_id            = var.vpc_id
  cidr_block        = cidrsubnet(var.vpc_cidr, var.newbits, (var.max_netnum - count.index - var.availability_zones_count))
  availability_zone = var.aws_availability_zone_names[count.index]
  tags = {
    az_index = count.index
    Name = "${var.vpc_name}-app-subnet-${count.index + 1}-${var.aws_availability_zone_names[count.index]}"
  }
}

## Create route tables for Aviatrix Spoke Gateways
resource "aws_route_table" "route_tables" {
  count             = var.availability_zones_count
  vpc_id            = var.vpc_id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = var.gateway_id
  }

  lifecycle {
    ignore_changes = [route]
  }

  tags = {
    az_index = count.index
    Name = "${var.vpc_name}-app-subnet-${count.index + 1}-${var.aws_availability_zone_names[count.index]}"
  }
}

## Create route table association for Aviatrix Spoke Gateways
resource "aws_route_table_association" "gw_route_table_association" {
  count             = var.availability_zones_count
  subnet_id      = aws_subnet.subnets[count.index].id
  route_table_id = aws_route_table.route_tables[count.index].id
}



output "subnets" {
  value = {
    for subnet in aws_subnet.subnets:
    subnet.tags.az_index => {
      "subnet_id" = subnet.id
      "subnet_cidr" = subnet.cidr_block
    }
  }
}