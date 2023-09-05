provider "aws" {
  region = "us-east-2"
}
module "webserver_cluster" {
  source = "../../../modules/services/webserver-cluster"

  cluster_name = "webservers-prod"
  db_remote_state_bucket = "zentropy-terraform-state"
  db_remote_state_key = "prod/data-stores/postgres/terraform.tfstate"
}