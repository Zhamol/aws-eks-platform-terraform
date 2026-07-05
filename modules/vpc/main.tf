terraform {
  required_version = ">= 1.7"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "${var.project_name}-vpc"
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

resource "aws_default_security_group" "default" {
  vpc_id = aws_vpc.main.id

  # no ingress or egress rules = restricts all traffic
  # CKV2_AWS_12: restrict default security group

  tags = {
    Name        = "${var.project_name}-default-sg-restricted"
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name        = "${var.project_name}-igw"
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

# CKV_AWS_130: disable auto-assign public IPs

resource "aws_subnet" "public" {
  count                   = length(var.public_subnet_cidrs) # → creates 2 subnets (index 0 and 1)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidrs[count.index] # index 0 → 10.0.1.0/24, index 1 → 10.0.3.0/24
  availability_zone       = var.availability_zones[count.index]  # index 0 → us-east-1a, index 1 → us-east-1b
  map_public_ip_on_launch = false

  tags = {
    Name        = "${var.project_name}-public-subnet-${count.index}" # unique name per subnet
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

resource "aws_subnet" "private" {
  count                   = length(var.private_subnet_cidrs) # → creates 2 subnets (index 0 and 1)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.private_subnet_cidrs[count.index] # index 0 → 10.0.2.0/24, index 1 → 10.0.4.0/24
  availability_zone       = var.availability_zones[count.index]   # index 0 → us-east-1a, index 1 → us-east-1b
  map_public_ip_on_launch = false

  tags = {
    Name                     = "${var.project_name}-private-subnet-${count.index}" # unique name per subnet
    Environment              = var.environment
    ManagedBy                = "terraform"
    "karpenter.sh/discovery" = "${var.project_name}-eks"
  }
}

resource "aws_eip" "nat" {
  domain = "vpc"

  tags = {
    Name        = "${var.project_name}-nat-eip"
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[0].id # NAT Gateway must be in a public subnet

  tags = {
    Name        = "${var.project_name}-nat-gateway"
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name        = "${var.project_name}-public-rt"
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main.id
  }

  tags = {
    Name        = "${var.project_name}-private-rt"
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

resource "aws_route_table_association" "public" {
  count          = length(var.public_subnet_cidrs) # → creates 2 associations (index 0 and 1)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  count          = length(var.private_subnet_cidrs) # → creates 2 associations (index 0 and 1)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}

# CKV_AWS_24: restrict SSH to a specific CIDR via variable (default disables SSH — use SSM Session Manager)
resource "aws_security_group" "ec2" {
  name        = "${var.project_name}-ec2-sg"
  description = "Security group for EC2 instances - SSH restricted by ssh_allowed_cidr variable"
  vpc_id      = aws_vpc.main.id

  dynamic "ingress" {
    for_each = var.ssh_allowed_cidr != "" ? [1] : []
    content {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = [var.ssh_allowed_cidr]
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-ec2-sg"
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

# CKV2_AWS_12: VPC flow logs
resource "aws_cloudwatch_log_group" "vpc_flow_log" {
  name              = "/aws/vpc/flow-log/${var.project_name}-${var.environment}"
  retention_in_days = 30

  tags = {
    Name        = "${var.project_name}-vpc-flow-logs"
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

data "aws_iam_policy_document" "vpc_flow_log_assume" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["vpc-flow-logs.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

data "aws_iam_policy_document" "vpc_flow_log" {
  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams",
    ]
    resources = [
      aws_cloudwatch_log_group.vpc_flow_log.arn,
      "${aws_cloudwatch_log_group.vpc_flow_log.arn}:*",
    ]
  }
}

resource "aws_iam_role" "vpc_flow_log" {
  name               = "${var.project_name}-${var.environment}-vpc-flow-log"
  assume_role_policy = data.aws_iam_policy_document.vpc_flow_log_assume.json

  tags = {
    Name        = "${var.project_name}-vpc-flow-log-role"
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

resource "aws_iam_role_policy" "vpc_flow_log" {
  name   = "${var.project_name}-${var.environment}-vpc-flow-log"
  role   = aws_iam_role.vpc_flow_log.id
  policy = data.aws_iam_policy_document.vpc_flow_log.json
}

resource "aws_flow_log" "main" {
  iam_role_arn    = aws_iam_role.vpc_flow_log.arn
  log_destination = aws_cloudwatch_log_group.vpc_flow_log.arn
  traffic_type    = "ALL"
  vpc_id          = aws_vpc.main.id

  tags = {
    Name        = "${var.project_name}-flow-log"
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}
