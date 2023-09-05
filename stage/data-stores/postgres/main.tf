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


module "postgres" {
  source = "../../../modules/data-stores/postgres"

  db_username = var.db_username
  db_password = var.db_password

}