provider "aws" {
  region = "us-west-2"
}



# AWS Secrets Manager
data "aws_secretsmanager_secret_version" "creds" {
  secret_id = "db-creds"
}

locals {
  #ENCRYPTED FILE
  #db_creds = yamldecode(data.aws_kms_secrets.creds.plaintext["db"])
  #AWS Secrets Manager
  db_creds = jsondecode(
    data.aws_secretsmanager_secret_version.creds.secret_string
  )
}

module "postgres" {
  source      = "../../../../modules/data-stores/postgres"
  db_name     = var.db_name
  db_password = local.db_creds.password
  db_username = local.db_creds.username
}

terraform {
  # Reminder this is partial config, must use terraform init -backend-config=backend.hcl (just init)
  backend "s3" {
    key = "stage/data-stores/postgres/terraform.tfstate"
  }
}