locals {
  http_port    = 80
  any_port     = 0
  any_protocol = "-1"
  tcp_protocol = "tcp"
  all_ips      = ["0.0.0.0/0"]
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

# Configure actual EC2 instance that runs basic busybox hello world serve
resource "aws_launch_configuration" "mem-overflow-launch-config" {
  image_id        = "ami-03f65b8614a860c29"
  instance_type   = var.instance_type # "t2.micro"
  security_groups = [aws_security_group.instance.id]

  # Render the User Data script as a template
  user_data = templatefile("${path.module}/user-data.sh", {
    server_port = var.server_port
    db_address  = data.terraform_remote_state.db.outputs.address
    db_port     = data.terraform_remote_state.db.outputs.port
  })

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

  min_size = var.min_size
  max_size = var.max_size

  tag {
    key                 = "Name"
    value               = var.cluster_name
    propagate_at_launch = true
  }
}

# Open port 8080 to all traffic
resource "aws_security_group" "instance" {
  name = "${var.cluster_name}-instance"

  ingress {
    from_port   = var.server_port
    to_port     = var.server_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Security group to allow ALB listeners to allow incoming reqs on 80 and allow all outgoing (for itself to communicate with VPCs)
resource "aws_security_group" "alb" {
  name = "${var.cluster_name}-alb"
}
resource "aws_security_group_rule" "allow_http_inbound" {
  type              = "ingress"
  security_group_id = aws_security_group.alb.id
  from_port         = local.http_port
  to_port           = local.http_port
  protocol          = local.tcp_protocol
  cidr_blocks       = local.all_ips
}

resource "aws_security_group_rule" "allow_all_outbound" {
  type              = "egress"
  security_group_id = aws_security_group.alb.id
  from_port         = local.any_port
  to_port           = local.any_port
  protocol          = local.any_protocol
  cidr_blocks       = local.all_ips
}


# Load balancer that will distribute traffic to the instances
resource "aws_lb" "mem-overflow-lb" {
  name               = "${var.cluster_name}-asg"
  load_balancer_type = "application"
  subnets            = data.aws_subnets.default.ids # Which VPC subnets to communicate on - default is WIDE OPEN
  security_groups    = [aws_security_group.alb.id]  # Security group to allow incoming requests on 80
}

# Target group checks instance health for the load balancer
resource "aws_lb_target_group" "asg" {
  name     = "${var.cluster_name}-asg"
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
  port              = local.http_port
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

data "terraform_remote_state" "db" {
  backend = "s3"
  config = {
    bucket = var.db_remote_state_bucket
    key    = var.db_remote_state_key
    region = "us-west-2"
  }
}

