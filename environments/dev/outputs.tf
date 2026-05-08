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