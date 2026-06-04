terraform {
  required_version = ">= 1.7"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

data "aws_caller_identity" "current" {}

# CKV_AWS_18: dedicated access logging bucket
#checkov:skip=CKV_AWS_18:This is the access log destination — logging to itself is not required
#checkov:skip=CKV2_AWS_62:Logging bucket does not require event notifications
#checkov:skip=CKV_AWS_21:Versioning not required for access logs bucket
#checkov:skip=CKV_AWS_144:Cross-region replication not required for lab
#checkov:skip=CKV_AWS_145:KMS encryption not required for lab, AES256 sufficient
resource "aws_s3_bucket" "logs" {
  bucket = "${var.project_name}-${var.environment}-${data.aws_caller_identity.current.account_id}-logs"

  tags = {
    Name        = "${var.project_name}-s3-logs"
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

resource "aws_s3_bucket_public_access_block" "logs" {
  bucket = aws_s3_bucket.logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "logs" {
  bucket = aws_s3_bucket.logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# CKV2_AWS_61: lifecycle for the logging bucket
#checkov:skip=CKV_AWS_300:Abort incomplete uploads not required for logs bucket
resource "aws_s3_bucket_lifecycle_configuration" "logs" {
  bucket = aws_s3_bucket.logs.id

  rule {
    id     = "expire-old-logs"
    status = "Enabled"

    expiration {
      days = 90
    }
  }
}

#checkov:skip=CKV_AWS_144:Cross-region replication not required for lab
#checkov:skip=CKV_AWS_145:KMS encryption not required for lab, AES256 sufficient
resource "aws_s3_bucket" "lab" {
  bucket = "${var.project_name}-${var.environment}-${data.aws_caller_identity.current.account_id}"

  tags = {
    Name        = "${var.project_name}-s3"
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

resource "aws_s3_bucket_versioning" "lab" {
  bucket = aws_s3_bucket.lab.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "lab" {
  bucket = aws_s3_bucket.lab.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "lab" {
  bucket = aws_s3_bucket.lab.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# CKV_AWS_18: access logging for the main bucket
resource "aws_s3_bucket_logging" "lab" {
  bucket        = aws_s3_bucket.lab.id
  target_bucket = aws_s3_bucket.logs.id
  target_prefix = "access-logs/"
}

# CKV2_AWS_61: lifecycle policy for main bucket
#checkov:skip=CKV_AWS_300:Abort incomplete uploads not critical for lab
resource "aws_s3_bucket_lifecycle_configuration" "lab" {
  bucket = aws_s3_bucket.lab.id

  rule {
    id     = "transition-noncurrent-versions"
    status = "Enabled"

    noncurrent_version_transition {
      noncurrent_days = 30
      storage_class   = "STANDARD_IA"
    }

    noncurrent_version_expiration {
      noncurrent_days = 90
    }
  }
}

# CKV2_AWS_62: event notifications via SQS
resource "aws_sqs_queue" "s3_events" {
  name                    = "${var.project_name}-${var.environment}-s3-events"
  sqs_managed_sse_enabled = true # CKV_AWS_27

  tags = {
    Name        = "${var.project_name}-s3-events"
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

resource "aws_sqs_queue_policy" "s3_events" {
  queue_url = aws_sqs_queue.s3_events.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "s3.amazonaws.com" }
      Action    = "sqs:SendMessage"
      Resource  = aws_sqs_queue.s3_events.arn
      Condition = {
        ArnEquals = {
          "aws:SourceArn" = aws_s3_bucket.lab.arn
        }
      }
    }]
  })
}

resource "aws_s3_bucket_notification" "lab" {
  bucket = aws_s3_bucket.lab.id

  queue {
    queue_arn = aws_sqs_queue.s3_events.arn
    events    = ["s3:ObjectCreated:*", "s3:ObjectRemoved:*"]
  }

  depends_on = [aws_sqs_queue_policy.s3_events]
}
