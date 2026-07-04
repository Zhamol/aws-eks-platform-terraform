variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16" # dev vpc cidr
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for the public subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.3.0/24"] # dev public subnets
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for the private subnets"
  type        = list(string)
  default     = ["10.0.2.0/24", "10.0.4.0/24"] # dev private subnets
}

variable "availability_zones" {
  description = "Availability zones for the VPC subnets"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "terraform-lab"
}

variable "account_id" {
  description = "AWS account ID for the dev environment"
  type        = string
}

variable "terraform_role_name" {
  description = "IAM role name to assume in this account for Terraform execution"
  type        = string
  default     = "OrganizationAccountAccessRole"
}

variable "public_access_cidrs" {
  description = "CIDRs allowed to access EKS public endpoint"
  type        = list(string)
}

variable "kubernetes_version" {
  description = "Kubernetes version for the EKS cluster"
  type        = string
}
