# Calculate VPC subnet mask bits
locals {
  vpc_mask_bits = tonumber(split("/", var.vpc_cidr)[1])
}

# Calculate subnet mask bit differences towards new subnets, will be used for cidrsubnet function
locals {
  newbits = 28 - local.vpc_mask_bits
}

# Calculate maxium number of subnets, will be used for cidrsubnet function
locals {
  max_netnum = pow(2, local.newbits) - 1
}