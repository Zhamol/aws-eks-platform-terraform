output "iam_role_arn" {
  description = "IAM role ARN for the AWS Load Balancer Controller service account"
  value       = aws_iam_role.this.arn
}

output "iam_policy_arn" {
  description = "IAM policy ARN for the AWS Load Balancer Controller"
  value       = aws_iam_policy.this.arn
}