# Secrets Manager Policies
# Allows GitLab CI role to read secrets (SSH keys, credentials)
# in dev and staging accounts during Terraform runs

# Allow GitLab CI role to read secrets in dev account
resource "aws_iam_role_policy" "dev_secrets" {
  provider = aws.dev
  name     = "gitlab-ci-secrets-access"
  role     = "OrganizationAccountAccessRole"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "secretsmanager:GetSecretValue",
        "secretsmanager:DescribeSecret"
      ]
      Resource = "arn:aws:secretsmanager:us-east-1:446598504905:secret:terraform-lab/*"
    }]
  })
}

# Allow GitLab CI role to read secrets in staging account
resource "aws_iam_role_policy" "staging_secrets" {
  provider = aws.staging
  name     = "gitlab-ci-secrets-access"
  role     = "OrganizationAccountAccessRole"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "secretsmanager:GetSecretValue",
        "secretsmanager:DescribeSecret"
      ]
      Resource = "arn:aws:secretsmanager:us-east-1:916292310732:secret:terraform-lab/*"
    }]
  })
}