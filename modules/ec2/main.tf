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

# Read public key from Secrets Manager
data "aws_secretsmanager_secret" "ec2_key" {
  name = "terraform-lab/ec2-public-key"
}

data "aws_secretsmanager_secret_version" "ec2_key" {
  secret_id = data.aws_secretsmanager_secret.ec2_key.id
}

resource "aws_key_pair" "lab" {
  key_name   = "${var.project_name}-key"
  public_key = data.aws_secretsmanager_secret_version.ec2_key.secret_string
}

resource "aws_instance" "lab" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  vpc_security_group_ids = [var.security_group_id]
  key_name               = aws_key_pair.lab.key_name

  tags = {
    Name        = "${var.project_name}-ec2"
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}