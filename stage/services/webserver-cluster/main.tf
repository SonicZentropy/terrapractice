provider "aws" {
  region = "us-west-2"
  # Reminder use IAM access creds for key/secret, not the ones that connect IAM accounts to amazon accounts
}

# Get default VPC for region
data "aws_vpc" "default" {
  default = true
}

# Get default subnet within the aws_vpc
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }

  # Add this filter to select only the subnets in the us-west-2[a-c] Availability Zone because 2d doesn't support t2.micro
  filter {
    name   = "availability-zone"
    values = ["us-west-2a", "us-west-2b", "us-west-2c"]
  }
}

# Open port 8080 to all traffic
resource "aws_security_group" "instance" {
  name = "mem-overflow-instance"

  ingress {
    from_port   = var.server_port
    to_port     = var.server_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
# Configure actual EC2 instance that runs basic busybox hello world serve
resource "aws_launch_configuration" "mem-overflow-launch-config" {
  image_id        = "ami-03f65b8614a860c29"
  instance_type   = "t2.micro"
  security_groups = [aws_security_group.instance.id]

  user_data = <<-EOF
              #!/bin/bash
              echo "Hello, World" > index.html
              nohup busybox httpd -f -p ${var.server_port} &
              EOF
  # Otherwise we'll destroy the old one first, but it will still have reference in the ASG
  lifecycle {
    create_before_destroy = true
  }
}

# Creates group of instances from 2 to 4 that will scale up based on demand behind the load balancer
resource "aws_autoscaling_group" "mem-overflow-asg" {
  launch_configuration = aws_launch_configuration.mem-overflow-launch-config.name # Name from launch config above
  vpc_zone_identifier  = data.aws_subnets.default.ids                             # Get subnet IDs from data source

  # Get list of health-checkers based on ASG
  target_group_arns = [aws_lb_target_group.asg.arn]
  health_check_type = "ELB" # ELB is enhanced version that will also watch for server unresponsive, similar to Compose postgres health checks

  min_size = 2
  max_size = 4

  tag {
    key                 = "Name"
    value               = "mem-overflow-asg"
    propagate_at_launch = true
  }
}

# Security group to allow ALB listeners to allow incoming reqs on 80 and allow all outgoing (for itself to communicate with VPCs)
resource "aws_security_group" "alb" {
  name = "mem-overflow-alb"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all outbound traffic for communicating with instances themselves
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


# Load balancer that will distribute traffic to the instances
resource "aws_lb" "mem-overflow-lb" {
  name               = "mem-overflow-asg"
  load_balancer_type = "application"
  subnets            = data.aws_subnets.default.ids # Which VPC subnets to communicate on - default is WIDE OPEN
  security_groups    = [aws_security_group.alb.id]  # Security group to allow incoming requests on 80
}

# Target group checks instance health for the load balancer
resource "aws_lb_target_group" "asg" {
  name     = "mem-overflow-asg"
  port     = var.server_port
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.default.id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 15
    timeout             = 3
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}


# This is what forwards the actual requests to the correct destination behind the load balancer
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.mem-overflow-lb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "404: Page not found"
      status_code  = 404
    }
  }
}

# Rule for forwarding traffic from load balancer - right now sends ALL traffic straight to target group VPCs
resource "aws_lb_listener_rule" "asg" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 100

  condition {
    path_pattern {
      values = ["*"]
    }
  }

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.asg.arn
  }
}


terraform {
  # Reminder this is partial config, must use terraform init -backend-config=backend.hcl (just init)
  backend "s3" {
    key = "stage/services/webserver-cluster/terraform.tfstate"
  }
}

