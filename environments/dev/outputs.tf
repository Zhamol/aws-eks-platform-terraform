output "instance_id" {
  description = "EC2 instance ID"
  value       = module.ec2.instance_id
}

output "public_ip" {
  description = "EC2 public IP — use this to SSH"
  value       = module.ec2.public_ip
}

output "bucket_name" {
  description = "S3 bucket name"
  value       = module.s3.bucket_name
}

output "bucket_arn" {
  description = "S3 bucket ARN"
  value       = module.s3.bucket_arn
}

output "ecr_repository_urls" {
  description = "ECR repository URLs"
  value       = module.ecr.repository_urls
}

output "ecr_repository_arns" {
  description = "ECR repository ARNs"
  value       = module.ecr.repository_arns
}

output "route53_zone_id" {
  description = "Route 53 hosted zone ID"
  value       = module.route53.zone_id
}

output "load_balancer_controller_role_arn" {
  description = "IAM role ARN for the AWS Load Balancer Controller"
  value       = module.load_balancer_controller.iam_role_arn
}

output "load_balancer_controller_policy_arn" {
  description = "IAM policy ARN for the AWS Load Balancer Controller"
  value       = module.load_balancer_controller.iam_policy_arn
}