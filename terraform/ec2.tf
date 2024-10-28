# Bastion Host AMI Data Source for Ubuntu 22.04 (x86_64)
data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]  # Ensure you're getting x86_64 architecture
  }

  owners = ["099720109477"]  # Ubuntu's account ID
}

# Bastion Host EC2 Instance
resource "aws_instance" "bastion_host" {
  ami                    = "ami-005fc0f236362e99f"  # Use the confirmed AMI ID
  instance_type         = "t2.micro"  # Free Tier eligible instance type
  vpc_security_group_ids = [aws_security_group.Bastion_Host.id]
  subnet_id             = aws_subnet.public_subnet_a.id
  key_name              = var.key_name
  tags = {
    Name = "Bastion Host"
  }
}
# -------------------------------------------------------------------------------------------------------------------
# -------------------------------------------------------------------------------------------------------------------
# -------------------------------------------------------------------------------------------------------------------
# Presentation EC2 Instance (Launch Template)
resource "aws_launch_template" "presentation_host" {
  image_id              = "ami-06b21ccaeff8cd686"  # Use the confirmed AMI ID
  instance_type         = "t2.micro"  # Free Tier eligible instance type
  vpc_security_group_ids = [aws_security_group.Presentation_EC2.id]
  key_name              = var.key_name

  user_data = base64encode(<<-EOF
  #!/bin/bash
# Update package list and install required packages
sudo yum update -y
sudo yum install -y git

# Install Node.js (use NodeSource for the latest version)
curl -fsSL https://rpm.nodesource.com/setup_18.x | sudo bash -
sudo yum install -y nodejs

# Install NGINX
sudo yum install -y nginx

# Start and enable NGINX
sudo systemctl start nginx
sudo systemctl enable nginx

# Define variables
REPO_URL="https://github.com/Ammb305/aws-threeTier-deployment.git"
BRANCH_NAME="feature/add-logging"
REPO_DIR="/home/ec2-user/aws-threeTier-deployment/frontend"
ENV_FILE="$REPO_DIR/.env"
APP_TIER_ALB_URL="http://internal-application-loadBalancer-1072175246.us-east-1.elb.amazonaws.com"  # Replace with your actual alb endpoint
API_URL="/api"

# Clone the repository as ec2-user
cd /home/ec2-user
sudo -u ec2-user git clone $REPO_URL
cd aws-threeTier-deployment

# Checkout to the specific branch
sudo -u ec2-user git checkout $BRANCH_NAME
cd frontend

# Ensure ec2-user owns the directory
sudo chown -R ec2-user:ec2-user /home/ec2-user/aws-threeTier-deployment

# Create .env file with the API_URL
echo "VITE_API_URL=\"$API_URL\"" >> "$ENV_FILE"

# Install Node.js dependencies as ec2-user
sudo -u ec2-user npm install

# Build the frontend application as ec2-user
sudo -u ec2-user npm run build

# Copy the build files to the NGINX directory
sudo cp -r dist /usr/share/nginx/html/

# Update NGINX configuration
NGINX_CONF="/etc/nginx/nginx.conf"
SERVER_NAME="<learningdevops.site www.learningdevops.site>"  # Replace with your actual domain name

# Backup existing NGINX configuration
sudo cp $NGINX_CONF $${NGINX_CONF}.bak

# Write new NGINX configuration
sudo tee $NGINX_CONF > /dev/null <<EOL
user nginx;
worker_processes auto;

error_log /var/log/nginx/error.log warn;
pid /run/nginx.pid;

events {
    worker_connections 1024;
}

http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    log_format main '\$remote_addr - \$remote_user [\$time_local] "\$request" '
                    '\$status \$body_bytes_sent "\$http_referer" '
                    '"\$http_user_agent" "\$http_x_forwarded_for"';

    access_log /var/log/nginx/access.log main;

    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    types_hash_max_size 2048;

    include /etc/nginx/conf.d/*.conf;
}
EOL

# Create a separate NGINX configuration file
sudo tee /etc/nginx/conf.d/presentation-tier.conf > /dev/null <<EOL
server {
    listen 80;
    server_name $SERVER_NAME;
    root /usr/share/nginx/html/dist;
    index index.html index.htm;

    #health check
    location /health {
        default_type text/html;
        return 200 "<!DOCTYPE html><p>Health check endpoint</p>\n";
    }

    location / {
        try_files \$uri /index.html;
    }

    location /api/ {
        proxy_pass $APP_TIER_ALB_URL;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOL
EOF
)

  tags = {
    Name = "Presentation Host/Frontend"
  }
}

# Target Group
resource "aws_lb_target_group" "Presentation_Target_Group" {
  name        = "tf-lb-tg"
  port        = 80
  protocol    = "HTTP"
  target_type = "instance"
  vpc_id      = aws_vpc.main.id

  health_check {
    path                = "/health"
    protocol            = "HTTP"
    healthy_threshold   = 5
    unhealthy_threshold = 2       
    timeout             = 5          
    interval            = 30
  }
}

# Load Balancer
resource "aws_lb" "Presentation_Load_Balancer" {
  name                      = "presentation-loadBalancer"
  internal                  = false
  load_balancer_type        = "application"
  security_groups           = [aws_security_group.Presentation_ALB.id]
  subnets                   = [aws_subnet.public_subnet_a.id, aws_subnet.public_subnet_b.id]
  enable_deletion_protection = false

  tags = {
    Name = "presentation loadBalancer"
  }
}

# Listener for the Load Balancer
resource "aws_lb_listener" "Presentation_Listener" {
  load_balancer_arn = aws_lb.Presentation_Load_Balancer.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.Presentation_Target_Group.arn  # Directly reference target group ARN
  }
}

# Auto Scaling Group (Presentation)
resource "aws_autoscaling_group" "presentation_asg" {
  name                = "presentation-AutoScalingGroup"
  vpc_zone_identifier = [aws_subnet.public_subnet_a.id, aws_subnet.public_subnet_b.id]
  desired_capacity     = 2
  min_size             = 2
  max_size             = 4
  health_check_type   = "ELB"
  health_check_grace_period = 300
  metrics_granularity = "1Minute"

  launch_template {
    id      = aws_launch_template.presentation_host.id
    version = "$Latest"
  }

  enabled_metrics = [
    "GroupDesiredCapacity",
    "GroupInServiceInstances",
    "GroupPendingInstances",
    "GroupTerminatingInstances",
    "GroupTotalInstances",
    "GroupMinSize",
    "GroupMaxSize",
  ]

  tag {
    key                 = "Name"
    value               = "presentation-asg-instance"
    propagate_at_launch = true
  }
}

# Autoscaling Group Attachment
resource "aws_autoscaling_attachment" "presentation_asg_attachment" {
  autoscaling_group_name = aws_autoscaling_group.presentation_asg.id
  lb_target_group_arn    = aws_lb_target_group.Presentation_Target_Group.arn
}

# Autoscaling Policy
resource "aws_autoscaling_policy" "target_tracking_policy" {
  name                   = "Target Tracking Policy"
  autoscaling_group_name = aws_autoscaling_group.presentation_asg.name
  policy_type           = "TargetTrackingScaling"

  target_tracking_configuration {
    target_value       = 50
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
  }
}
# -------------------------------------------------------------------------------------------------------------------
# -------------------------------------------------------------------------------------------------------------------
# -------------------------------------------------------------------------------------------------------------------
# Application EC2 Instance (Launch Template)
resource "aws_launch_template" "application_host" {
  name = "Application_EC2"
  image_id = "ami-06b21ccaeff8cd686" # Amazon Linux 2023
  instance_type = "t2.micro"
  key_name = var.key_name
  vpc_security_group_ids = [aws_security_group.Application_EC2.id]

  user_data = base64encode(<<-EOF
  #!/bin/bash 

# Update package list and install required packages 
sudo yum update -y 
sudo yum install -y git 

# Install Node.js (use NodeSource for the latest version) 
curl -fsSL https://rpm.nodesource.com/setup_18.x | sudo bash - 
sudo yum install -y nodejs 

# Install PM2 globally 
sudo npm install -g pm2 

# Define variables 
REPO_URL="https://github.com/Ammb305/aws-threeTier-deployment.git" 
BRANCH_NAME="main" 
REPO_DIR="/home/ec2-user/aws-threeTier-deployment/backend" 
ENV_FILE="$REPO_DIR/.env" 

# Clone the repository 
cd /home/ec2-user 
sudo -u ec2-user git clone $REPO_URL 
cd aws-threeTier-deployment

# Checkout to the specific branch 
sudo -u ec2-user git checkout $BRANCH_NAME 
cd backend 

# Define the log directory and ensure it exists 
LOG_DIR="/home/ec2-user/aws-threeTier-deployment/backend/logs" 
mkdir -p $LOG_DIR 
sudo chown -R ec2-user:ec2-user $LOG_DIR

# Append environment variables to the .env file
echo "LOG_DIR=$LOG_DIR" >> "$ENV_FILE"
echo "DB_HOST=\"terraform-20241027185710975700000001.c5g22ewq4ztf.us-east-1.rds.amazonaws.com\"" >> "$ENV_FILE"
echo "DB_PORT=\"3306\"" >> "$ENV_FILE"
echo "DB_USER=\"admin\"" >> "$ENV_FILE"
echo "DB_PASSWORD=\"admin123\"" >> "$ENV_FILE"  # Replace with actual password
echo "DB_NAME=\"MySQLdatabase\"" >> "$ENV_FILE"

# Install Node.js dependencies as ec2-user
sudo -u ec2-user npm install

# Start the application using PM2 as ec2-user
sudo -u ec2-user pm2 start server.js --name "my-app" # Make sure you specify the correct entry file

# Ensure PM2 restarts on reboot
sudo -u ec2-user pm2 startup systemd 
sudo -u ec2-user pm2 save

# Add a sleep command if necessary to ensure dependencies are ready
sleep 5

EOF
)

  tags = {
    Name = "Application EC2"
  }
}

# Target Group (Application)
resource "aws_lb_target_group" "Application_Target_Group" {
  name        = "application-tg"
  port        = 3200
  protocol    = "HTTP"
  target_type = "instance"
  vpc_id      = aws_vpc.main.id

  health_check {
    path                = "/health"
    protocol            = "HTTP"
    healthy_threshold   = 5
    unhealthy_threshold = 2       
    timeout             = 5          
    interval            = 30
  }
}

# Load Balancer for (Application)
resource "aws_lb" "Application_Load_Balancer" {
  name                      = "application-loadBalancer"
  internal                  = true
  load_balancer_type        = "application"
  security_groups           = [aws_security_group.Application_ALB.id]
  subnets                   = [aws_subnet.private_subnet_a1.id, aws_subnet.private_subnet_b1.id]
  enable_deletion_protection = false

  tags = {
    Name = "presentation loadBalancer"
  }
}

# Listener for the Load Balancer (Application)
resource "aws_lb_listener" "Application_Listener" {
  load_balancer_arn = aws_lb.Application_Load_Balancer.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.Application_Target_Group.arn  # Directly reference target group ARN
  }
}

# Auto Scaling Group (Application)
resource "aws_autoscaling_group" "Application_asg" {
  name                = "application-AutoScalingGroup"
  vpc_zone_identifier = [aws_subnet.private_subnet_a1.id, aws_subnet.private_subnet_b1.id]
  desired_capacity     = 2
  min_size             = 2
  max_size             = 4
  health_check_type   = "ELB"
  health_check_grace_period = 300
  metrics_granularity = "1Minute"

  launch_template {
    id      = aws_launch_template.application_host.id
    version = "$Latest"
  }

  enabled_metrics = [
    "GroupDesiredCapacity",
    "GroupInServiceInstances",
    "GroupPendingInstances",
    "GroupTerminatingInstances",
    "GroupTotalInstances",
    "GroupMinSize",
    "GroupMaxSize",
  ]

  tag {
    key                 = "Name"
    value               = "application-asg-instance"
    propagate_at_launch = true
  }
}

# Autoscaling Group Attachment
resource "aws_autoscaling_attachment" "application_asg_attachment" {
  autoscaling_group_name = aws_autoscaling_group.Application_asg.id
  lb_target_group_arn    = aws_lb_target_group.Application_Target_Group.arn
}

# Autoscaling Policy
resource "aws_autoscaling_policy" "application_target_tracking_policy" {
  name                   = "Target Tracking Policy"
  autoscaling_group_name = aws_autoscaling_group.Application_asg.name
  policy_type           = "TargetTrackingScaling"

  target_tracking_configuration {
    target_value       = 50
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
  }
}