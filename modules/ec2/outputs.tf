output "instance_id" {
  description = "EC2 instance ID"
  value       = aws_instance.lab.id
}

output "public_ip" {
  description = "EC2 public IP address"
  value       = aws_instance.lab.public_ip
}

output "key_name" {
  description = "Key pair name"
  value       = aws_key_pair.lab.key_name
}