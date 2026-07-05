output "repository_urls" {
  description = "Map of ECR repository names to repository URLs"

  value = {
    for name, repository in aws_ecr_repository.this :
    name => repository.repository_url
  }
}

output "repository_arns" {
  description = "Map of ECR repository names to repository ARNs"

  value = {
    for name, repository in aws_ecr_repository.this :
    name => repository.arn
  }
}