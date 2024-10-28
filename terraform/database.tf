resource "aws_db_subnet_group" "rds_subnet_group" {
  name       = "main"
  subnet_ids = [aws_subnet.private_subnet_a1.id, aws_subnet.private_subnet_b1.id]

  tags = {
    Name = "RDS Subnet Group"
  }
}
# Database Creation
resource "aws_db_instance" "multi_az_mysql" {
  allocated_storage    = 25
  db_name              = "MySQLdatabase"
  engine               = "mysql"
  engine_version       = "8.0"
  instance_class       = "db.t3.micro"
  username             = "admin"           
  password             = "admin123"         
  parameter_group_name = "default.mysql8.0"
  vpc_security_group_ids = [aws_security_group.Database.id]
  db_subnet_group_name = aws_db_subnet_group.rds_subnet_group.name
  multi_az             = true               
  skip_final_snapshot  = true

  
  tags = {
    Name = "MySQL-MultiAZ"
    Environment = "Dev/Test"
  }
}
