# The VPC within which we run our builds
resource "aws_vpc" "build_vpc" {
  cidr_block = "10.66.66.0/23"

  tags = "${var.tags}"
}

# Public subnet of the VPC
resource "aws_subnet" "build_public_subnet" {
  vpc_id = "${aws_vpc.build_vpc.id}"
  cidr_block = "10.66.67.0/24"

  depends_on = [
    "aws_internet_gateway.build_igw"
  ]

  tags = "${var.tags}"
}

# Subnet of the VPC in which we run our pipeline
resource "aws_subnet" "build_private_subnet" {
  vpc_id = "${aws_vpc.build_vpc.id}"
  cidr_block = "10.66.66.0/24"

  depends_on = [
    "aws_internet_gateway.build_igw"
  ]

  tags = "${var.tags}"
}

# EIP for the NAT gateway
resource "aws_eip" "build_eip" {
  vpc = true
  
  depends_on = [
    "aws_internet_gateway.build_igw"
  ]

  tags = "${var.tags}"
}

# The NAT gateway for the VPC
resource "aws_nat_gateway" "build_nat_gw" {
  allocation_id = "${aws_eip.build_eip.id}"
  subnet_id = "${aws_subnet.build_public_subnet.id}"

  depends_on = [
    "aws_internet_gateway.build_igw"
  ]

  tags = "${var.tags}"
}

# The internet gateway for the VPC
resource "aws_internet_gateway" "build_igw" {
  vpc_id = "${aws_vpc.build_vpc.id}"

  tags = "${var.tags}"
}

# Default route table, which routes all external traffic through the
# NAT gateway
resource "aws_default_route_table" "build_default_route_table" {
  default_route_table_id = "${aws_vpc.build_vpc.default_route_table_id}"

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = "${aws_nat_gateway.build_nat_gw.id}"
  }

  tags = "${var.tags}"
}

# Route table for our public subnet, which routes all external traffic
# through the internet gateway
resource "aws_route_table" "build_public_route_table" {
  vpc_id = "${aws_vpc.build_vpc.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.build_igw.id}"
  }

  tags = "${var.tags}"
}

# Associate the route table with the public subnet
resource "aws_route_table_association" "association" {
  subnet_id = "${aws_subnet.build_public_subnet.id}"
  route_table_id = "${aws_route_table.build_public_route_table.id}"
}
