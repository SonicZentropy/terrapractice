output "ecr_repo_url" {
  value       = aws_ecr_repository.app_ecr_repo.repository_url
  description = "URL to our Elastic Compute Container Registry"
}