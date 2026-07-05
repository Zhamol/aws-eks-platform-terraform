resource "aws_ecr_repository" "this" {
  for_each = var.repository_names

  name                 = each.value
  image_tag_mutability = "IMMUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "AES256"
  }

  tags = {
    Name        = each.value
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

resource "aws_ecr_lifecycle_policy" "this" {
  for_each = aws_ecr_repository.this

  repository = each.value.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep only the latest ${var.images_to_keep} images"

        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = var.images_to_keep
        }

        action = {
          type = "expire"
        }
      }
    ]
  })
}



