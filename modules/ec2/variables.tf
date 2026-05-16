variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "subnet_id" {
  description = "Subnet ID where EC2 will launch"
  type        = string
}

variable "security_group_id" {
  description = "Security group ID to attach to EC2"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "project_name" {
  description = "Project name used for tagging"
  type        = string
}

variable "ec2_key_secret_name" {
  description = "Secrets Manager secret name containing the EC2 public key"
  type        = string
  default     = "terraform-lab/ec2-public-key"
}