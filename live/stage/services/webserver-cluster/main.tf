provider "aws" {
  region = "us-west-2"
}

module "webserver_cluster" {
  source       = "../../../../modules/services/webserver-cluster"
  cluster_name = var.cluster_name

  db_remote_state_bucket = var.db_remote_state_bucket
  db_remote_state_key    = var.db_remote_state_key

  instance_type = "t2.micro"
  min_size      = 2
  max_size      = 3
  enable_autoscaling = false
}

# Allows testing via connecting to port 12345 ONLY on staging, does not affect prod
resource "aws_security_group_rule" "allow_testing_inbound" {
  type              = "ingress"
  security_group_id = module.webserver_cluster.alb_security_group_id
  from_port         = 12345
  to_port           = 12345
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
}

terraform {
  # Reminder this is partial config, must use terraform init -backend-config=backend.hcl (just init)
  backend "s3" {
    key = "stage/services/webserver-cluster/terraform.tfstate"
  }
}