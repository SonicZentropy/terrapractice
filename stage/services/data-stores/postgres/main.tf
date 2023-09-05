terraform {
  backend "s3" {
    # Replace this with your bucket name!
    bucket         = "zentropy-terraform-state"
    key            = "stage/data-stores/postgres/terraform.tfstate"
    region         = "us-east-2"
    # Replace this with your DynamoDB table name!
    dynamodb_table = "zentropy-terraform-locks"
    encrypt        = true
  }
}

provider "aws" {
  region = "us-east-2"
}

resource "aws_db_instance" "example" {
  identifier = "zentropy-terraform"
  engine = "postgres"
  allocated_storage = 10
  instance_class = "db.t3.micro"
  skip_final_snapshot = true
  db_name = "doggr"

  username = var.db_username
  password = var.db_password
}