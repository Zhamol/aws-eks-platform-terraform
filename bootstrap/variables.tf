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

variable "oidc_thumbprint" {
  description = "GitLab OIDC TLS thumbprint — update if GitLab rotates their certificate"
  type        = string
  default     = "9e99a48a9960b14926bb7f3b02e22da2b0ab7280"
}

variable "github_repository" {
  description = "GitHub repository allowed to assume the Terraform role"
  type        = string
  default     = "Zhamol/aws-eks-platform-terraform"
}

variable "github_dev_environment" {
  description = "GitHub Environment allowed to assume the dev Terraform role"
  type        = string
  default     = "dev"
}

variable "github_staging_environment" {
  description = "GitHub Environment allowed to assume the staging Terraform role"
  type        = string
  default     = "staging"
}
