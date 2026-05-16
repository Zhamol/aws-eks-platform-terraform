variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "subnet_cidr" {
  description = "CIDR block for the public subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "private_subnet_cidr" {
  description = "CIDR block for private subnet"
  type        = string
  default     = "10.0.2.0/24"
}

variable "availability_zone" {
  description = "AZ to deploy subnets"
  type        = string
  default     = "us-east-1a"
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "project_name" {
  description = "Project name used for tagging"
  type        = string
}

variable "ssh_allowed_cidr" {
  description = "CIDR allowed to SSH to EC2 instances. Empty string disables port 22 (use SSM Session Manager instead)."
  type        = string
  default     = ""
}