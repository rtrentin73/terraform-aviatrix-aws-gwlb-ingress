# Create GWLB endpoint subnet
resource "aws_subnet" "gwlbe_subnets" {
  count             = var.availability_zones_count
  vpc_id            = var.vpc_id
  cidr_block        = cidrsubnet(var.vpc_cidr, var.newbits, count.index)
  availability_zone = var.aws_availability_zone_names[count.index]
  tags = {
    az_index = count.index
    Name = "${var.vpc_name}-gwlbe-subnet-${count.index + 1}-${var.aws_availability_zone_names[count.index]}"
  }
}

## Create route table association for GWLB endpoints
resource "aws_route_table_association" "gwlbe_route_table_association" {
  count          = var.availability_zones_count
  subnet_id      = aws_subnet.gwlbe_subnets[count.index].id
  route_table_id = var.route_table_id  
}


# Create GWLB endpoints
resource "aws_vpc_endpoint" "gwlbe" {
  count             = var.availability_zones_count
  service_name      = var.gwlb_endpoint_service_name
  subnet_ids        = [aws_subnet.gwlbe_subnets[count.index].id]
  vpc_endpoint_type = "GatewayLoadBalancer"
  vpc_id            = var.vpc_id
  tags = {
    az_index = count.index
    Name = "${var.vpc_name}-gwlbe-${count.index + 1}-${var.aws_availability_zone_names[count.index]}"
  }
}

output "gwlbe" {
  value = {
    for endpoint in aws_vpc_endpoint.gwlbe:
    endpoint.tags.az_index => endpoint.id
  }
}