set fallback := true

init:
    terraform init -backend-config=../../config/backend.hcl
apply:
    terraform apply
plan:
    terraform plan
destroy:
    echo "ECR REGISTRY SHOULD NEVER BE DESTROYED!  Aborting..."
