terraform {
  required_version = ">= 1.7"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

data "aws_region" "current" {}

data "aws_iam_policy_document" "controller_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [var.oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${replace(var.oidc_issuer_url, "https://", "")}:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "${replace(var.oidc_issuer_url, "https://", "")}:sub"
      values = [
        "system:serviceaccount:kube-system:karpenter"
      ]
    }
  }
}

resource "aws_iam_role" "controller" {
  name = "${var.project_name}-${var.environment}-karpenter-controller"

  assume_role_policy = data.aws_iam_policy_document.controller_assume_role.json

  tags = {
    Name             = "${var.project_name}-${var.environment}-karpenter-controller"
    Project          = var.project_name
    Environment      = var.environment
    ManagedBy        = "Terraform"
    KarpenterVersion = var.karpenter_version
  }
}

data "aws_iam_policy_document" "node_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "node" {
  name = "${var.project_name}-${var.environment}-karpenter-node"

  assume_role_policy = data.aws_iam_policy_document.node_assume_role.json

  tags = {
    Name             = "${var.project_name}-${var.environment}-karpenter-node"
    Project          = var.project_name
    Environment      = var.environment
    ManagedBy        = "Terraform"
    KarpenterVersion = var.karpenter_version
  }
}

resource "aws_iam_role_policy_attachment" "node_worker_policy" {
  role       = aws_iam_role.node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "node_cni_policy" {
  role       = aws_iam_role.node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "node_ecr_policy" {
  role       = aws_iam_role.node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_instance_profile" "node" {
  name = "${var.project_name}-${var.environment}-karpenter-node"
  role = aws_iam_role.node.name

  tags = {
    Name        = "${var.project_name}-${var.environment}-karpenter-node"
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

resource "aws_sqs_queue" "interruption" {
  name                      = "${var.project_name}-${var.environment}-karpenter-interruption"
  message_retention_seconds = 300
  sqs_managed_sse_enabled   = true

  tags = {
    Name        = "${var.project_name}-${var.environment}-karpenter-interruption"
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

resource "aws_cloudwatch_event_rule" "spot_interruption" {
  name        = "${var.project_name}-${var.environment}-karpenter-spot-interruption"
  description = "Capture EC2 Spot interruption warnings for Karpenter"

  event_pattern = jsonencode({
    source      = ["aws.ec2"]
    detail-type = ["EC2 Spot Instance Interruption Warning"]
  })

  tags = {
    Name        = "${var.project_name}-${var.environment}-karpenter-spot-interruption"
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

resource "aws_cloudwatch_event_target" "spot_interruption" {
  rule      = aws_cloudwatch_event_rule.spot_interruption.name
  target_id = "KarpenterInterruptionQueue"
  arn       = aws_sqs_queue.interruption.arn
}

resource "aws_cloudwatch_event_rule" "rebalance_recommendation" {
  name        = "${var.project_name}-${var.environment}-karpenter-rebalance"
  description = "Capture EC2 rebalance recommendations for Karpenter"

  event_pattern = jsonencode({
    source      = ["aws.ec2"]
    detail-type = ["EC2 Instance Rebalance Recommendation"]
  })

  tags = {
    Name        = "${var.project_name}-${var.environment}-karpenter-rebalance"
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

resource "aws_cloudwatch_event_target" "rebalance_recommendation" {
  rule      = aws_cloudwatch_event_rule.rebalance_recommendation.name
  target_id = "KarpenterInterruptionQueue"
  arn       = aws_sqs_queue.interruption.arn
}

resource "aws_cloudwatch_event_rule" "instance_state_change" {
  name        = "${var.project_name}-${var.environment}-karpenter-instance-state-change"
  description = "Capture EC2 instance state changes for Karpenter"

  event_pattern = jsonencode({
    source      = ["aws.ec2"]
    detail-type = ["EC2 Instance State-change Notification"]
    detail = {
      state = [
        "stopping",
        "stopped",
        "shutting-down",
        "terminated"
      ]
    }
  })

  tags = {
    Name        = "${var.project_name}-${var.environment}-karpenter-instance-state-change"
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

resource "aws_cloudwatch_event_target" "instance_state_change" {
  rule      = aws_cloudwatch_event_rule.instance_state_change.name
  target_id = "KarpenterInterruptionQueue"
  arn       = aws_sqs_queue.interruption.arn
}

resource "aws_cloudwatch_event_rule" "scheduled_change" {
  name        = "${var.project_name}-${var.environment}-karpenter-scheduled-change"
  description = "Capture AWS Health scheduled changes for Karpenter"

  event_pattern = jsonencode({
    source      = ["aws.health"]
    detail-type = ["AWS Health Event"]
  })

  tags = {
    Name        = "${var.project_name}-${var.environment}-karpenter-scheduled-change"
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

resource "aws_cloudwatch_event_target" "scheduled_change" {
  rule      = aws_cloudwatch_event_rule.scheduled_change.name
  target_id = "KarpenterInterruptionQueue"
  arn       = aws_sqs_queue.interruption.arn
}

data "aws_iam_policy_document" "interruption_queue" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }

    actions = [
      "sqs:SendMessage"
    ]

    resources = [
      aws_sqs_queue.interruption.arn
    ]

    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"

      values = [
        aws_cloudwatch_event_rule.spot_interruption.arn,
        aws_cloudwatch_event_rule.rebalance_recommendation.arn,
        aws_cloudwatch_event_rule.instance_state_change.arn,
        aws_cloudwatch_event_rule.scheduled_change.arn,
        aws_cloudwatch_event_rule.capacity_reservation_interruption.arn
      ]
    }
  }
}

resource "aws_sqs_queue_policy" "interruption" {
  queue_url = aws_sqs_queue.interruption.id
  policy    = data.aws_iam_policy_document.interruption_queue.json
}



data "aws_iam_policy_document" "controller" {
  statement {
    sid    = "AllowInterruptionQueueActions"
    effect = "Allow"

    actions = [
      "sqs:DeleteMessage",
      "sqs:GetQueueUrl",
      "sqs:ReceiveMessage"
    ]

    resources = [
      aws_sqs_queue.interruption.arn
    ]
  }

  statement {
    sid    = "AllowRegionalReadActions"
    effect = "Allow"

    actions = [
      "ec2:DescribeCapacityReservations",
      "ec2:DescribeImages",
      "ec2:DescribeInstances",
      "ec2:DescribeInstanceStatus",
      "ec2:DescribeInstanceTypeOfferings",
      "ec2:DescribeInstanceTypes",
      "ec2:DescribeLaunchTemplates",
      "ec2:DescribePlacementGroups",
      "ec2:DescribeSecurityGroups",
      "ec2:DescribeSpotPriceHistory",
      "ec2:DescribeSubnets"
    ]

    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "aws:RequestedRegion"
      values   = [data.aws_region.current.name]
    }
  }

  statement {
    sid    = "AllowSSMReadActions"
    effect = "Allow"

    actions = [
      "ssm:GetParameter"
    ]

    resources = [
      "arn:aws:ssm:${data.aws_region.current.name}::parameter/aws/service/*"
    ]
  }

  statement {
    sid    = "AllowPricingReadActions"
    effect = "Allow"

    actions = [
      "pricing:GetProducts"
    ]

    resources = ["*"]
  }

  statement {
    sid    = "AllowClusterDiscovery"
    effect = "Allow"

    actions = [
      "eks:DescribeCluster"
    ]

    resources = [
      "arn:aws:eks:${data.aws_region.current.name}:*:cluster/${var.cluster_name}"
    ]
  }

  statement {
    sid    = "AllowPassNodeRole"
    effect = "Allow"

    actions = [
      "iam:PassRole"
    ]

    resources = [
      aws_iam_role.node.arn
    ]

    condition {
      test     = "StringEquals"
      variable = "iam:PassedToService"
      values = [
        "ec2.amazonaws.com",
        "ec2.amazonaws.com.cn"
      ]
    }
  }

  statement {
    sid    = "AllowScopedInstanceProfileActions"
    effect = "Allow"

    actions = [
      "iam:AddRoleToInstanceProfile",
      "iam:CreateInstanceProfile",
      "iam:DeleteInstanceProfile",
      "iam:GetInstanceProfile",
      "iam:RemoveRoleFromInstanceProfile",
      "iam:TagInstanceProfile"
    ]

    resources = [
      "arn:aws:iam::*:instance-profile/*"
    ]
  }

  # Creation actions are scoped to resources Karpenter itself tags as owned by
  # this cluster — the EC2NodeClass must set the tag
  # kubernetes.io/cluster/${var.cluster_name} = "owned" on launched resources.
  statement {
    sid    = "AllowScopedEC2CreationActions"
    effect = "Allow"

    actions = [
      "ec2:CreateFleet",
      "ec2:CreateLaunchTemplate",
      "ec2:CreateTags",
      "ec2:RunInstances"
    ]

    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "aws:RequestedRegion"
      values   = [data.aws_region.current.name]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:RequestTag/kubernetes.io/cluster/${var.cluster_name}"
      values   = ["owned"]
    }
  }

  # Deletion actions are scoped to resources already tagged as owned by this
  # cluster, so this role can't terminate/delete instances or launch
  # templates outside what Karpenter created for this cluster.
  statement {
    sid    = "AllowScopedEC2DeletionActions"
    effect = "Allow"

    actions = [
      "ec2:DeleteLaunchTemplate",
      "ec2:TerminateInstances"
    ]

    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "aws:RequestedRegion"
      values   = [data.aws_region.current.name]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:ResourceTag/kubernetes.io/cluster/${var.cluster_name}"
      values   = ["owned"]
    }
  }
}

resource "aws_iam_policy" "controller" {
  name        = "${var.project_name}-${var.environment}-karpenter-controller"
  description = "IAM policy for the Karpenter controller"
  policy      = data.aws_iam_policy_document.controller.json

  tags = {
    Name             = "${var.project_name}-${var.environment}-karpenter-controller"
    Project          = var.project_name
    Environment      = var.environment
    ManagedBy        = "Terraform"
    KarpenterVersion = var.karpenter_version
  }
}

resource "aws_iam_role_policy_attachment" "controller" {
  role       = aws_iam_role.controller.name
  policy_arn = aws_iam_policy.controller.arn
}



resource "aws_cloudwatch_event_rule" "capacity_reservation_interruption" {
  name        = "${var.project_name}-${var.environment}-karpenter-capacity-reservation-interruption"
  description = "Capture EC2 Capacity Reservation interruption warnings for Karpenter"

  event_pattern = jsonencode({
    source      = ["aws.ec2"]
    detail-type = ["EC2 Capacity Reservation Instance Interruption Warning"]
  })

  tags = {
    Name        = "${var.project_name}-${var.environment}-karpenter-capacity-reservation-interruption"
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

resource "aws_cloudwatch_event_target" "capacity_reservation_interruption" {
  rule      = aws_cloudwatch_event_rule.capacity_reservation_interruption.name
  target_id = "KarpenterInterruptionQueue"
  arn       = aws_sqs_queue.interruption.arn
}