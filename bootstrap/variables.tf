variable "gitlab_project_path" {
  description = "GitLab project path for OIDC condition (e.g. group/repo)"
  type        = string
  default     = "Zhamol/terraform-lab"
}

variable "dev_account_id" {
  description = "Dev AWS account ID"
  type        = string
  default     = "446598504905"
}

variable "staging_account_id" {
  description = "Staging AWS account ID"
  type        = string
  default     = "916292310732"
}

variable "aws_region" {
  description = "AWS region used for resource ARNs"
  type        = string
  default     = "us-east-1"
}

variable "oidc_thumbprint" {
  description = "GitLab OIDC TLS thumbprint — update if GitLab rotates their certificate"
  type        = string
  default     = "9e99a48a9960b14926bb7f3b02e22da2b0ab7280"
}