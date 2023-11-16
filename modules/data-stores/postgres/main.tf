provider "aws" {
  region = "us-west-2"
}

# Encrypted File via AWS CLI
data "aws_kms_secrets" "creds" {
  secret {
    name    = "db"
    payload = file("${path.module}/db-creds.yml.encrypted")
  }
}

resource "aws_db_instance" "mem-overflow" {
  identifier_prefix   = "zentropy-mem-overflow"
  engine              = "postgres"
  allocated_storage   = 10
  instance_class      = "db.t3.micro"
  skip_final_snapshot = true
  db_name             = var.db_name
  # How should we set the username and password?
  username = var.db_username
  password = var.db_password
}