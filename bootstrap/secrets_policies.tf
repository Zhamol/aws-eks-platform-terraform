# Purpose-built Terraform execution roles in each child account.
# These replace direct modification of the AWS-managed OrganizationAccountAccessRole.
# The GitLab CI role in the management account is granted sts:AssumeRole into these.
#
# After applying bootstrap, update terraform_role_name in each environment to "terraform-ci".

locals {
  ci_managed_policies = toset([
    "arn:aws:iam::aws:policy/AmazonEC2FullAccess",
    "arn:aws:iam::aws:policy/AmazonVPCFullAccess",
    "arn:aws:iam::aws:policy/AmazonS3FullAccess",
    "arn:aws:iam::aws:policy/IAMFullAccess",
    "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess",
    "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess",
    "arn:aws:iam::aws:policy/SecretsManagerReadWrite",
    "arn:aws:iam::aws:policy/AmazonSQSFullAccess",
  ])
}

# Dev account — dedicated Terraform execution role
resource "aws_iam_role" "terraform_dev" {
  provider = aws.dev
  name     = "terraform-ci"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { AWS = aws_iam_role.gitlab_ci.arn }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = {
    Environment = "dev"
    ManagedBy   = "terraform"
  }
}

resource "aws_iam_role_policy_attachment" "terraform_dev" {
  for_each   = local.ci_managed_policies
  provider   = aws.dev
  role       = aws_iam_role.terraform_dev.name
  policy_arn = each.value
}

# Staging account — dedicated Terraform execution role
resource "aws_iam_role" "terraform_staging" {
  provider = aws.staging
  name     = "terraform-ci"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { AWS = aws_iam_role.gitlab_ci.arn }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = {
    Environment = "staging"
    ManagedBy   = "terraform"
  }
}

resource "aws_iam_role_policy_attachment" "terraform_staging" {
  for_each   = local.ci_managed_policies
  provider   = aws.staging
  role       = aws_iam_role.terraform_staging.name
  policy_arn = each.value
}
