# Allow GitLab CI role to access dev state bucket
resource "aws_s3_bucket_policy" "dev_state" {
  bucket   = "terraform-state-${var.dev_account_id}"
  provider = aws.dev

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        AWS = aws_iam_role.gitlab_ci.arn
      }
      Action = [
        "s3:ListBucket",
        "s3:GetObject",
        "s3:PutObject",
        "s3:DeleteObject"
      ]
      Resource = [
        "arn:aws:s3:::terraform-state-${var.dev_account_id}",
        "arn:aws:s3:::terraform-state-${var.dev_account_id}/*"
      ]
    }]
  })
}

# Allow GitLab CI role to access staging state bucket
resource "aws_s3_bucket_policy" "staging_state" {
  bucket   = "terraform-state-${var.staging_account_id}"
  provider = aws.staging

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        AWS = aws_iam_role.gitlab_ci.arn
      }
      Action = [
        "s3:ListBucket",
        "s3:GetObject",
        "s3:PutObject",
        "s3:DeleteObject"
      ]
      Resource = [
        "arn:aws:s3:::terraform-state-${var.staging_account_id}",
        "arn:aws:s3:::terraform-state-${var.staging_account_id}/*"
      ]
    }]
  })
}