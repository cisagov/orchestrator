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

# ACL for the private subnet of the VPC
resource "aws_network_acl" "build_default_acl" {
  vpc_id = "${aws_vpc.build_vpc.id}"
  subnet_ids = [
    "${aws_subnet.build_private_subnet.id}"
  ]

  # Allow ephemeral ports from anywhere
  ingress {
    protocol = "tcp"
    rule_no = 100
    action = "allow"
    cidr_block = "0.0.0.0/0"
    from_port = 1024
    to_port = 65535
  }

  # Allow HTTP (needed for apt-get)
  egress {
    protocol = "tcp"
    rule_no = 100
    action = "allow"
    cidr_block = "0.0.0.0/0"
    from_port = 80
    to_port = 80
  }

  # Allow HTTPS
  egress {
    protocol = "tcp"
    rule_no = 110
    action = "allow"
    cidr_block = "0.0.0.0/0"
    from_port = 443
    to_port = 443
  }

  tags = "${var.tags}"
}

# ACL for the public-facing subnet of the VPC
resource "aws_network_acl" "build_public_acl" {
  vpc_id = "${aws_vpc.build_vpc.id}"
  subnet_ids = [
    "${aws_subnet.build_public_subnet.id}"
  ]

  # Allow ephemeral ports from anywhere
  ingress {
    protocol = "tcp"
    rule_no = 100
    action = "allow"
    cidr_block = "0.0.0.0/0"
    from_port = 0
    to_port = 65535
  }

  # Allow HTTP (needed for apt-get)
  egress {
    protocol = "tcp"
    rule_no = 100
    action = "allow"
    cidr_block = "0.0.0.0/0"
    from_port = 80
    to_port = 80
  }

  # Allow HTTPS
  egress {
    protocol = "tcp"
    rule_no = 110
    action = "allow"
    cidr_block = "0.0.0.0/0"
    from_port = 443
    to_port = 443
  }

  # Allow egress to the private subnet via ephemeral ports
  egress {
    protocol = "tcp"
    rule_no = 120
    action = "allow"
    cidr_block = "${aws_subnet.build_private_subnet.cidr_block}"
    from_port = 1024
    to_port = 65535
  }

  tags = "${var.tags}"
}

# Security group for the private portion of the VPC
resource "aws_security_group" "build_private_sg" {
  vpc_id = "${aws_vpc.build_vpc.id}"

  # Allow ephemeral ports from anywhere
  ingress {
    protocol = "tcp"
    cidr_blocks = [
      "0.0.0.0/0"
    ]
    from_port = 1024
    to_port = 65535
  }

  # Allow HTTP (needed for apt-get)
  egress {
    protocol = "tcp"
    cidr_blocks = [
      "0.0.0.0/0"
    ]
    from_port = 80
    to_port = 80
  }

  # Allow HTTPS
  egress {
    protocol = "tcp"
    cidr_blocks = [
      "0.0.0.0/0"
    ]
    from_port = 443
    to_port = 443
  }

  tags = "${var.tags}"
}

# Security group for the public portion of the VPC
resource "aws_security_group" "build_public_sg" {
  vpc_id = "${aws_vpc.build_vpc.id}"

  tags = "${var.tags}"
}
