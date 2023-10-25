provider "aws" {
  region = "us-west-2"
}
resource "aws_db_instance" "mem-overflow" {
  identifier_prefix   = "zentropy-mem-overflow"
  engine              = "postgres"
  allocated_storage   = 10
  instance_class      = "db.t3.micro"
  skip_final_snapshot = true
  db_name             = "mem_overflow"
  # How should we set the username and password?
  username = var.db_username
  password = var.db_password
}

terraform {
  # Reminder this is partial config, must use terraform init -backend-config=backend.hcl (just init)
  backend "s3" {
    key = "prod/data-stores/postgres/terraform.tfstate"
  }
}