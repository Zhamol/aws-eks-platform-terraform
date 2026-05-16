data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

data "aws_secretsmanager_secret" "ec2_key" {
  name = var.ec2_key_secret_name
}

data "aws_secretsmanager_secret_version" "ec2_key" {
  secret_id = data.aws_secretsmanager_secret.ec2_key.id
}

resource "aws_key_pair" "lab" {
  key_name   = "${var.project_name}-key"
  public_key = data.aws_secretsmanager_secret_version.ec2_key.secret_string
}

# CKV2_AWS_41: IAM instance profile for EC2
data "aws_iam_policy_document" "ec2_assume" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "ec2" {
  name               = "${var.project_name}-${var.environment}-ec2"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume.json

  tags = {
    Name        = "${var.project_name}-ec2-role"
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

# SSM Session Manager access — no need to open port 22
resource "aws_iam_role_policy_attachment" "ec2_ssm" {
  role       = aws_iam_role.ec2.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ec2" {
  name = "${var.project_name}-${var.environment}-ec2"
  role = aws_iam_role.ec2.name
}

resource "aws_instance" "lab" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  vpc_security_group_ids = [var.security_group_id]
  key_name               = aws_key_pair.lab.key_name
  monitoring             = true                               # CKV_AWS_126
  iam_instance_profile   = aws_iam_instance_profile.ec2.name # CKV2_AWS_41

  # CKV_AWS_79: enforce IMDSv2
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  # CKV_AWS_8: encrypt root EBS volume
  root_block_device {
    encrypted = true
  }

  tags = {
    Name        = "${var.project_name}-ec2"
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}
