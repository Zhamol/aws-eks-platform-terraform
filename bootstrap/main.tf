# Bootstrap — runs once to set up foundation
# Creates: OIDC provider, GitLab CI role, multi-account providers
# Run with: make bootstrap-oidc

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket         = "terraform-state-940920597829"
    key            = "bootstrap/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-state-lock"
    encrypt        = true
  }
}

# Management account provider (default)
provider "aws" {
  region = "us-east-1"
}

# Dev account provider
provider "aws" {
  alias  = "dev"
  region = "us-east-1"
  assume_role {
    role_arn = "arn:aws:iam::446598504905:role/OrganizationAccountAccessRole"
  }
}

# Staging account provider
provider "aws" {
  alias  = "staging"
  region = "us-east-1"
  assume_role {
    role_arn = "arn:aws:iam::916292310732:role/OrganizationAccountAccessRole"
  }
}

# OIDC Provider
resource "aws_iam_openid_connect_provider" "gitlab" {
  url             = "https://gitlab.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["9e99a48a9960b14926bb7f3b02e22da2b0ab7280"]
}

# IAM Role for GitLab CI
resource "aws_iam_role" "gitlab_ci" {
  name = "gitlab-ci-terraform"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = aws_iam_openid_connect_provider.gitlab.arn
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringLike = {
          "gitlab.com:sub" = "project_path:${var.gitlab_project_path}:*"
        }
      }
    }]
  })
}

# Give GitLab CI admin access
resource "aws_iam_role_policy_attachment" "gitlab_ci" {
  role       = aws_iam_role.gitlab_ci.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
} 