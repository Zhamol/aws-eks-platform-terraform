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