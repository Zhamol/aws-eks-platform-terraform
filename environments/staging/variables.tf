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
