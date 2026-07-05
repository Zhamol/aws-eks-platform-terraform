output "gitlab_ci_role_arn" {
  description = "IAM role ARN for GitLab CI (management account)"
  value       = aws_iam_role.gitlab_ci.arn
}

output "oidc_provider_arn" {
  description = "OIDC provider ARN"
  value       = aws_iam_openid_connect_provider.gitlab.arn
}

output "github_oidc_provider_arn" {
  description = "GitHub Actions OIDC provider ARN"
  value       = aws_iam_openid_connect_provider.github.arn
}

output "github_actions_dev_role_arn" {
  description = "IAM role ARN for GitHub Actions dev environment"
  value       = aws_iam_role.github_actions_dev.arn
}

output "github_actions_staging_role_arn" {
  description = "IAM role ARN for GitHub Actions staging environment"
  value       = aws_iam_role.github_actions_staging.arn
}

output "dev_terraform_role_arn" {
  description = "Terraform execution role ARN in the dev account — set as terraform_role_name=terraform-ci in environments/dev"
  value       = aws_iam_role.terraform_dev.arn
}

output "staging_terraform_role_arn" {
  description = "Terraform execution role ARN in the staging account — set as terraform_role_name=terraform-ci in environments/staging"
  value       = aws_iam_role.terraform_staging.arn
}
