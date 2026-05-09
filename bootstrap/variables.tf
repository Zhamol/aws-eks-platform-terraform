variable "gitlab_project_path" {
  description = "GitLab project path for OIDC condition"
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