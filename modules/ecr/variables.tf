variable "repository_names" {
  description = "Names of the ECR repositories to create"
  type        = set(string)
}

variable "environment" {
  description = "Environment name, such as dev or staging"
  type        = string
}

variable "project_name" {
  description = "Project name used for resource tags"
  type        = string
}

variable "images_to_keep" {
  description = "Number of images to keep in each ECR repository"
  type        = number
  default     = 20
}