variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "staging"
}

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "terraform-lab"
}

variable "account_id" {
  description = "AWS account ID for the staging environment"
  type        = string
  default     = "916292310732"
}

variable "terraform_role_name" {
  description = "IAM role name to assume in this account for Terraform execution"
  type        = string
  default     = "OrganizationAccountAccessRole"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.1.0.0/16" # staging — different from dev!
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for the public subnets"
  type        = list(string)
  default     = ["10.1.1.0/24", "10.1.3.0/24"] # staging public subnets
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for the private subnets"
  type        = list(string)
  default     = ["10.1.2.0/24", "10.1.4.0/24"] # staging private subnets
}

variable "availability_zones" {
  description = "Availability zones for the VPC subnets"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}