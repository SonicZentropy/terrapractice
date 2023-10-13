This repo uses [just](https://github.com/casey/just) for management of init flags.  You can use `just [web|s3|postgres] [init|plan|apply] from anywhere in the project to perform terraform actions on that piece.

# Ch 3 notes
- Takes 2 steps to properly configure state for a project
1. Write Terraform code to create the S3 bucket and DynamoDB table, and deploy that code with a local backend.
2. Go back to the Terraform code, add a remote backend configuration to it to use the newly created S3 bucket and DynamoDB table, and run terraform init to copy your local state to S3.

To delete the S3 bucket and dynamodb table:
1. Go to the Terraform code, remove the backend configuration, and rerun terraform init to copy the Terraform state back to your local disk.
2. Run terraform destroy to delete the S3 bucket and DynamoDB table.

you can share a single S3 bucket and DynamoDB table across all of your Terraform code, so you’ll
probably only need to do it once
