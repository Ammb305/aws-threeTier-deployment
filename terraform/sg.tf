# Bastion Host Security Group
resource "aws_security_group" "Bastion_Host" {
  name        = "Bastion Host SSH" 
  description = "Allow SSH access to Bastion Host"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Bastion Host SSH"
  }
}

# Presentation ALB Security Group
resource "aws_security_group" "Presentation_ALB" {
  name        = "Presentation ALB HTTP" 
  description = "Allow HTTP access to Presentation ALB"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Presentation Tier ALB"
  }
}

# Presentation EC2 Security Group
# Presentation EC2 Security Group
resource "aws_security_group" "Presentation_EC2" {
  name        = "Presentation EC2 HTTP" 
  description = "Allow HTTP access to Presentation EC2"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Allow SSH from anywhere (for testing purposes, restrict in production)
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    security_groups = [aws_security_group.Presentation_ALB.id]  # HTTP from Application ALB
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Presentation EC2 HTTP"
  }
}

# Application Tier Load Balancer Security Group
resource "aws_security_group" "Application_ALB" {
  name        = "Application ALB HTTP" 
  description = "Allow HTTP access to Application ALB"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    security_groups = [aws_security_group.Presentation_EC2.id]  # Allow HTTP from Presentation EC2
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"] 
  }

  tags = {
    Name = "Application Tier ALB"
  }
}

# Application Tier EC2 Security Group
resource "aws_security_group" "Application_EC2" {
  name        = "Application EC2 HTTP" 
  description = "Allow HTTP access to Application EC2"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    # security_groups = [aws_security_group.Bastion_Host.id]  # SSH from Bastion Host
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port       = 3200
    to_port         = 3200
    protocol        = "tcp"
    security_groups = [aws_security_group.Application_ALB.id]  # HTTP from Application ALB
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Application Tier EC2"
  }
}

# Database Tier Security Group
resource "aws_security_group" "Database" {
  name        = "Database Tier" 
  description = "Allow MySQL access to Database"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.Bastion_Host.id]  # MySQL from Application EC2
  }

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.Application_ALB.id]  # MySQL from Bastion Host
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
output "Database_ID" {
  value = aws_security_group.Database.id
}
