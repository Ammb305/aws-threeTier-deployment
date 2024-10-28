# VPC 
resource "aws_vpc" "main" {
  cidr_block       = var.vpc_cidr
  instance_tenancy = "default"

  tags = {
    Name = "Three Tier VPC"
  }
}
output "vpc_id" {
  value = aws_vpc.main.id
}

# Public Subnets
resource "aws_subnet" "public_subnet_a" {
  vpc_id              = aws_vpc.main.id
  cidr_block          = "10.0.1.0/24"
  availability_zone   = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "Public Subnet A"
  }
}

resource "aws_subnet" "public_subnet_b" {
  vpc_id              = aws_vpc.main.id
  cidr_block          = "10.0.2.0/24"
  availability_zone   = "us-east-1b"
  map_public_ip_on_launch = true

  tags = {
    Name = "Public Subnet B"
  }
}

# Private Subnets
resource "aws_subnet" "private_subnet_a1" {
  vpc_id              = aws_vpc.main.id
  cidr_block          = "10.0.3.0/24"
  availability_zone   = "us-east-1a"

  tags = {
    Name = "Private Subnet A1"
  }
}

resource "aws_subnet" "private_subnet_a2" {
  vpc_id              = aws_vpc.main.id
  cidr_block          = "10.0.4.0/24"
  availability_zone   = "us-east-1a"

  tags = {
    Name = "Private Subnet A2"
  }
}

resource "aws_subnet" "private_subnet_b1" {
  vpc_id              = aws_vpc.main.id
  cidr_block          = "10.0.5.0/24"
  availability_zone   = "us-east-1b"

  tags = {
    Name = "Private Subnet B1"
  }
}

resource "aws_subnet" "private_subnet_b2" {
  vpc_id              = aws_vpc.main.id
  cidr_block          = "10.0.6.0/24"
  availability_zone   = "us-east-1b"

  tags = {
    Name = "Private Subnet B2"
  }
}

output "private_subnet_a1_id" {
  value = aws_subnet.private_subnet_a1.id
}

output "private_subnet_b1_id" {
  value = aws_subnet.private_subnet_b1.id
}

# Internet Gateway
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "main"
  }
}

# Public Route Tables
resource "aws_route_table" "route_table_public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0" # Route to Internet Gateway for public access
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "Route Table Public"
  }
}

resource "aws_route_table_association" "public_a" {
  subnet_id      = aws_subnet.public_subnet_a.id
  route_table_id = aws_route_table.route_table_public.id
}

resource "aws_route_table_association" "public_b" {
  subnet_id      = aws_subnet.public_subnet_b.id
  route_table_id = aws_route_table.route_table_public.id
}

# NAT Gateway
resource "aws_eip" "eip" {
  domain = "vpc"
}

resource "aws_nat_gateway" "NATGateway" {
  allocation_id = aws_eip.eip.id
  subnet_id     = aws_subnet.public_subnet_a.id # Change to a public subnet

  tags = {
    Name = "NAT Gateway"
  }

  depends_on = [aws_internet_gateway.gw]
}

# Private Route Tables
resource "aws_route_table" "route_table_private" {
  count  = 4
  vpc_id = aws_vpc.main.id

  route {
    cidr_block      = "0.0.0.0/0"
    nat_gateway_id  = aws_nat_gateway.NATGateway.id
  }

  tags = {
    Name = "Route Table Private ${count.index + 1}"
  }
}

resource "aws_route_table_association" "private_association" {
  count          = 4
  subnet_id      = element([
    aws_subnet.private_subnet_a1.id,
    aws_subnet.private_subnet_a2.id,
    aws_subnet.private_subnet_b1.id,
    aws_subnet.private_subnet_b2.id
  ], count.index)

  route_table_id = aws_route_table.route_table_private[count.index].id
}
