# Get default VPC for my region
data "aws_vpc" "default" {
  default = true
}

# Get default subnet within the aws_vpc
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
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
# Configure actual EC2 instance that runs basic busybox hello world server
resource "aws_launch_configuration" "example" {
  image_id        = "ami-0fb653ca2d3203ac1"
  instance_type   = "t2.micro"
  security_groups = [aws_security_group.instance.id]

  user_data = templatefile("./user-data.sh", {
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
resource "aws_autoscaling_group" "example" {
  launch_configuration = aws_launch_configuration.example.name # Name from launch config above
  vpc_zone_identifier  = data.aws_subnets.default.ids # Get subnet IDs from data source

  # Get list of health-checkers based on ASG
  target_group_arns = [aws_lb_target_group.asg.arn]
  health_check_type = "ELB"
  # ELB is enhanced version that will also watch for server unresponsive instead of purely relying on AWS status

  min_size = 2
  max_size = 4

  tag {
    key                 = "Name"
    value               = var.cluster_name
    propagate_at_launch = true
  }
}

# Security group to allow ALB listeners to allow incoming reqs on 80 and allow all outgoing (for itself to communicate with VPCs)
resource "aws_security_group" "alb" {
  name = "${var.cluster_name}-alb"

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
resource "aws_lb" "example" {
  name               = var.cluster_name
  load_balancer_type = "application"
  subnets            = data.aws_subnets.default.ids # Which VPC subnets to communicate on - default is WIDE OPEN
  security_groups    = [aws_security_group.alb.id] # Security group to allow incoming requests on 80
}

# Target group checks instance health for the load balancer
resource "aws_lb_target_group" "asg" {
  name     = var.cluster_name
  port     = var.server_port
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.default.id

  health_check {
    path              = "/"
    protocol          = "HTTP"
    matcher           = "200"
    interval          = 15
    timeout           = 3
    healthy_threshold = 2
  }
}


# This is what forwards the actual requests to the correct destination behind the load balancer
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.example.arn
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

# Rule for forwarding traffic from load balancer - right now just goes straight to target group VPCs
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
  config  = {
    #bucket = "zentropy-terraform-state"
    bucket = var.db_remote_state_bucket
    #key    = "stage/data-stores/postgres/terraform.tfstate"
    key = var.db_remote_state_key
    region = "us-east-2"
  }
}