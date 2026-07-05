output "controller_role_arn" {
  description = "IAM role ARN for the Karpenter controller"
  value       = aws_iam_role.controller.arn
}

output "node_role_arn" {
  description = "IAM role ARN for EC2 nodes launched by Karpenter"
  value       = aws_iam_role.node.arn
}

output "node_role_name" {
  description = "IAM role name for EC2 nodes launched by Karpenter"
  value       = aws_iam_role.node.name
}

output "instance_profile_name" {
  description = "Instance profile name for Karpenter nodes"
  value       = aws_iam_instance_profile.node.name
}

output "interruption_queue_name" {
  description = "SQS interruption queue name for Karpenter"
  value       = aws_sqs_queue.interruption.name
}