# Bootstrap — runs once to set up foundation
# Creates: OIDC provider, GitLab CI role, multi-account providers
# Run with: make bootstrap-oidc

terraform {
  required_version = ">= 1.7"

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
  thumbprint_list = [var.oidc_thumbprint]
}

# GitHub Actions OIDC Provider
resource "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = [
    "sts.amazonaws.com"
  ]

  thumbprint_list = [
    "6938fd4d98bab03faadb97b34396831e3780aea1"
  ]
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

# IAM Role for GitHub Actions — dev environment
resource "aws_iam_role" "github_actions_dev" {
  name = "github-actions-terraform-dev"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [{
      Effect = "Allow"

      Principal = {
        Federated = aws_iam_openid_connect_provider.github.arn
      }

      Action = "sts:AssumeRoleWithWebIdentity"

      Condition = {
        StringEquals = {
          "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          "token.actions.githubusercontent.com:sub" = "repo:${var.github_repository}:environment:${var.github_dev_environment}"
        }
      }
    }]
  })
}

# Allow dev GitHub Actions to assume only the dev Terraform execution role
resource "aws_iam_role_policy" "github_actions_dev_assume_role" {
  name = "assume-dev-terraform-execution-role"
  role = aws_iam_role.github_actions_dev.id

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [{
      Effect = "Allow"
      Action = "sts:AssumeRole"

      Resource = [
        "arn:aws:iam::${var.dev_account_id}:role/terraform-ci",
      ]
    }]
  })
}

# IAM Role for GitHub Actions — staging environment
resource "aws_iam_role" "github_actions_staging" {
  name = "github-actions-terraform-staging"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [{
      Effect = "Allow"

      Principal = {
        Federated = aws_iam_openid_connect_provider.github.arn
      }

      Action = "sts:AssumeRoleWithWebIdentity"

      Condition = {
        StringEquals = {
          "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          "token.actions.githubusercontent.com:sub" = "repo:${var.github_repository}:environment:${var.github_staging_environment}"
        }
      }
    }]
  })
}

# Allow staging GitHub Actions to assume only the staging Terraform execution role
resource "aws_iam_role_policy" "github_actions_staging_assume_role" {
  name = "assume-staging-terraform-execution-role"
  role = aws_iam_role.github_actions_staging.id

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [{
      Effect = "Allow"
      Action = "sts:AssumeRole"

      Resource = [
        "arn:aws:iam::${var.staging_account_id}:role/terraform-ci",
      ]
    }]
  })
}

# Preserve existing GitLab AdministratorAccess during GitHub Actions migration.
# Remove only after GitHub Actions authentication and Terraform plan are verified.
resource "aws_iam_role_policy_attachment" "gitlab_ci" {
  role       = aws_iam_role.gitlab_ci.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

# Scoped managed policies for GitLab CI — replaces AdministratorAccess (CKV_AWS_355)
resource "aws_iam_role_policy_attachment" "gitlab_ci_ec2" {
  role       = aws_iam_role.gitlab_ci.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2FullAccess"
}

resource "aws_iam_role_policy_attachment" "gitlab_ci_vpc" {
  role       = aws_iam_role.gitlab_ci.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonVPCFullAccess"
}

resource "aws_iam_role_policy_attachment" "gitlab_ci_s3" {
  role       = aws_iam_role.gitlab_ci.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

resource "aws_iam_role_policy_attachment" "gitlab_ci_iam" {
  role       = aws_iam_role.gitlab_ci.name
  policy_arn = "arn:aws:iam::aws:policy/IAMFullAccess"
}

resource "aws_iam_role_policy_attachment" "gitlab_ci_dynamodb" {
  role       = aws_iam_role.gitlab_ci.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess"
}

resource "aws_iam_role_policy_attachment" "gitlab_ci_cloudwatch" {
  role       = aws_iam_role.gitlab_ci.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
}

resource "aws_iam_role_policy_attachment" "gitlab_ci_secrets" {
  role       = aws_iam_role.gitlab_ci.name
  policy_arn = "arn:aws:iam::aws:policy/SecretsManagerReadWrite"
}

resource "aws_iam_role_policy_attachment" "gitlab_ci_sqs" {
  role       = aws_iam_role.gitlab_ci.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSQSFullAccess"
}
