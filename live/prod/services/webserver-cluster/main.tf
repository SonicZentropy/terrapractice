provider "aws" {
	region = "us-west-2"
}
module "webserver_cluster" {
	source                 = "../../../../modules/services/webserver-cluster"
	cluster_name           = var.cluster_name
	db_remote_state_bucket = var.db_remote_state_bucket
	db_remote_state_key    = var.db_remote_state_key

	instance_type      = "t2.micro" #IRL should probably use a bigger one, but those aren't free
	min_size           = 2
	max_size           = 10
	enable_autoscaling = true #Make autoscaling depend upon hours of the day instead of hard coded

	custom_tags = {
		Owner     = "Casey Bailey"
		ManagedBy = "terraform"
	}
}

terraform {
	# Reminder this is partial config, must use terraform init -backend-config=backend.hcl (just init)
	backend "s3" {
		key = "prod/services/webserver-cluster/terraform.tfstate"
	}
}