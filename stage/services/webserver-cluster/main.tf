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
module "webserver_cluster" {
  source = "../../../modules/services/webserver-cluster"

  cluster_name = var.cluster_name
  db_remote_state_bucket = var.db_remote_state_bucket
  db_remote_state_key = var.db_remote_state_key
}