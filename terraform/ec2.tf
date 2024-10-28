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

# Presentation EC2 Instance (Launch Template)
resource "aws_launch_template" "presentation_host" {
  image_id              = "ami-005fc0f236362e99f"  # Use the confirmed AMI ID
  instance_type         = "t2.micro"  # Free Tier eligible instance type
  vpc_security_group_ids = [aws_security_group.Presentation_EC2.id]
  key_name              = var.key_name

  user_data = base64encode(<<-EOF
  #!/bin/bash
  sudo apt update -y
  sudo apt install nginx -y
  sudo systemctl start nginx
  sudo systemctl enable nginx

  echo "Healthy" | sudo tee /var/www/html/health

  sudo bash -c "cat > /var/www/html/index.html <<HTML
  <h1>Instance Details</h1>
  <p><b>Instance ID:</b> \$(curl -s http://169.254.169.254/latest/meta-data/instance-id)</p>
  <p><b>Availability Zone:</b> \$(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone)</p>
  <p><b>Public IP:</b> \$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)</p>
  HTML"

  sudo systemctl restart nginx
EOF
)

  tags = {
    Name = "Presentation Host/Frontend"
  }
}


# Target Group
resource "aws_lb_target_group" "Target_Group" {
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
resource "aws_lb" "Load_Balancer" {
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
resource "aws_lb_listener" "Listener" {
  load_balancer_arn = aws_lb.Load_Balancer.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "forward"

    target_group_arn = aws_lb_target_group.Target_Group.arn  # Directly reference target group ARN
  }
}

# Auto Scaling Group
resource "aws_autoscaling_group" "presentation_asg" {
  name                = "presentation-AutoScalingGroup"
  vpc_zone_identifier = [aws_subnet.public_subnet_a.id, aws_subnet.public_subnet_b.id]
  desired_capacity     = 2
  min_size             = 2
  max_size             = 4
  health_check_type   = "ELB"
  health_check_grace_period = 300

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
  lb_target_group_arn    = aws_lb_target_group.Target_Group.arn
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

# Application EC2 Instance (Launch Template)
resource "aws_launch_template" {
  name = "Application_EC2"
  image_id = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"
  key_name = var.key_name
  vpc_security_group_ids = [aws_security_group.Application_EC2.id]


}