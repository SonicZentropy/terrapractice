provider "aws" {
  region = "us-west-2"
}


terraform {
  # Reminder this is partial config, must use terraform init -backend-config=backend.hcl (just init)
  backend "s3" {
    key = "live/global/infrastructure/ecr-registry/terraform.tfstate"
  }
}

module "ecr_repository" {
  source = "../../../../modules/infrastructure/ecr-registry"
}

output "ecr_repo_url" {
  value       = module.ecr_repository.ecr_repo_url
  description = "URL to our Elastic Compute Container Registry"
}