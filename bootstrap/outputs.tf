output "gitlab_ci_role_arn" {
  description = "IAM role ARN for GitLab CI"
  value       = aws_iam_role.gitlab_ci.arn
}

output "oidc_provider_arn" {
  description = "OIDC provider ARN"
  value       = aws_iam_openid_connect_provider.gitlab.arn
}