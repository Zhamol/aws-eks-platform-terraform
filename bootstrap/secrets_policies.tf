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
    "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess",
    "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess",
    "arn:aws:iam::aws:policy/SecretsManagerReadWrite",
    "arn:aws:iam::aws:policy/AmazonSQSFullAccess",
  ])

  staging_ci_managed_policies = setunion(local.ci_managed_policies, toset([
    "arn:aws:iam::aws:policy/IAMFullAccess",
  ]))

  dev_terraform_managed_role_arns = [
    "arn:aws:iam::${var.dev_account_id}:role/terraform-lab-dev-aws-load-balancer-controller",
    "arn:aws:iam::${var.dev_account_id}:role/terraform-lab-dev-ec2",
    "arn:aws:iam::${var.dev_account_id}:role/terraform-lab-dev-karpenter-controller",
    "arn:aws:iam::${var.dev_account_id}:role/terraform-lab-dev-karpenter-node",
    "arn:aws:iam::${var.dev_account_id}:role/terraform-lab-dev-vpc-flow-log",
    "arn:aws:iam::${var.dev_account_id}:role/terraform-lab-eks-cluster-role",
    "arn:aws:iam::${var.dev_account_id}:role/terraform-lab-eks-node-role",
  ]

  dev_terraform_managed_policy_arns = [
    "arn:aws:iam::${var.dev_account_id}:policy/terraform-lab-dev-aws-load-balancer-controller",
    "arn:aws:iam::${var.dev_account_id}:policy/terraform-lab-dev-karpenter-controller",
  ]

  dev_terraform_managed_instance_profile_arns = [
    "arn:aws:iam::${var.dev_account_id}:instance-profile/terraform-lab-dev-ec2",
    "arn:aws:iam::${var.dev_account_id}:instance-profile/terraform-lab-dev-karpenter-node",
  ]

  dev_terraform_attachable_policy_arns = concat(local.dev_terraform_managed_policy_arns, [
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
    "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy",
    "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
    "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController",
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
  ])
}

# Dev account — dedicated Terraform execution role
resource "aws_iam_role" "terraform_dev" {
  provider = aws.dev
  name     = "terraform-ci"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        AWS = [
          aws_iam_role.gitlab_ci.arn,
          aws_iam_role.github_actions_dev.arn,
          "arn:aws:iam::940920597829:user/terraform",
        ]
      }
      Action = "sts:AssumeRole"
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

data "aws_iam_policy_document" "terraform_dev_platform" {
  statement {
    sid    = "EcrRead"
    effect = "Allow"

    actions = [
      "ecr:DescribeImages",
      "ecr:DescribeRepositories",
      "ecr:GetLifecyclePolicy",
      "ecr:GetLifecyclePolicyPreview",
      "ecr:ListTagsForResource",
    ]

    resources = [
      "arn:aws:ecr:us-east-1:${var.dev_account_id}:repository/sample-api",
    ]
  }

  statement {
    sid    = "EcrManagement"
    effect = "Allow"

    actions = [
      "ecr:CreateRepository",
      "ecr:DeleteLifecyclePolicy",
      "ecr:DeleteRepository",
      "ecr:PutImageScanningConfiguration",
      "ecr:PutImageTagMutability",
      "ecr:PutLifecyclePolicy",
      "ecr:TagResource",
      "ecr:UntagResource",
    ]

    resources = [
      "arn:aws:ecr:us-east-1:${var.dev_account_id}:repository/sample-api",
    ]
  }

  statement {
    sid    = "EksRead"
    effect = "Allow"

    actions = [
      "eks:DescribeAccessEntry",
      "eks:DescribeCluster",
      "eks:DescribeNodegroup",
      "eks:ListAccessEntries",
      "eks:ListTagsForResource",
    ]

    resources = [
      "arn:aws:eks:us-east-1:${var.dev_account_id}:cluster/terraform-lab-eks",
      "arn:aws:eks:us-east-1:${var.dev_account_id}:nodegroup/terraform-lab-eks/terraform-lab-node-group/*",
      "arn:aws:eks:us-east-1:${var.dev_account_id}:access-entry/terraform-lab-eks/*",
    ]
  }

  statement {
    sid    = "EksManagement"
    effect = "Allow"

    actions = [
      "eks:CreateAccessEntry",
      "eks:CreateCluster",
      "eks:CreateNodegroup",
      "eks:DeleteAccessEntry",
      "eks:DeleteCluster",
      "eks:DeleteNodegroup",
      "eks:TagResource",
      "eks:UntagResource",
      "eks:UpdateAccessEntry",
      "eks:UpdateClusterConfig",
      "eks:UpdateClusterVersion",
      "eks:UpdateNodegroupConfig",
      "eks:UpdateNodegroupVersion",
    ]

    resources = [
      "arn:aws:eks:us-east-1:${var.dev_account_id}:cluster/terraform-lab-eks",
      "arn:aws:eks:us-east-1:${var.dev_account_id}:nodegroup/terraform-lab-eks/terraform-lab-node-group/*",
      "arn:aws:eks:us-east-1:${var.dev_account_id}:access-entry/terraform-lab-eks/*",
    ]
  }

  statement {
    sid    = "EventBridgeManagement"
    effect = "Allow"

    actions = [
      "events:DeleteRule",
      "events:DescribeRule",
      "events:ListTagsForResource",
      "events:ListTargetsByRule",
      "events:PutRule",
      "events:PutTargets",
      "events:RemoveTargets",
      "events:TagResource",
      "events:UntagResource",
    ]

    resources = [
      "arn:aws:events:us-east-1:${var.dev_account_id}:rule/terraform-lab-dev-karpenter-*",
    ]
  }

  statement {
    sid    = "KmsCreate"
    effect = "Allow"

    actions = [
      "kms:CreateKey",
      "kms:TagResource",
    ]

    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "aws:RequestTag/Environment"
      values   = ["dev"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:RequestTag/ManagedBy"
      values   = ["terraform"]
    }
  }

  statement {
    sid    = "KmsManagement"
    effect = "Allow"

    actions = [
      "kms:CancelKeyDeletion",
      "kms:DescribeKey",
      "kms:DisableKeyRotation",
      "kms:EnableKeyRotation",
      "kms:GetKeyPolicy",
      "kms:GetKeyRotationStatus",
      "kms:ListResourceTags",
      "kms:PutKeyPolicy",
      "kms:ScheduleKeyDeletion",
      "kms:TagResource",
      "kms:UntagResource",
      "kms:UpdateKeyDescription",
      "kms:CreateGrant",
    ]

    resources = [
      "arn:aws:kms:us-east-1:${var.dev_account_id}:key/*",
    ]

    condition {
      test     = "StringEquals"
      variable = "aws:ResourceTag/Environment"
      values   = ["dev"]
    }
  }

  statement {
    sid    = "PassTerraformManagedRoles"
    effect = "Allow"

    actions = [
      "iam:PassRole",
    ]

    resources = [
      "arn:aws:iam::${var.dev_account_id}:role/terraform-lab-dev-ec2",
      "arn:aws:iam::${var.dev_account_id}:role/terraform-lab-dev-vpc-flow-log",
      "arn:aws:iam::${var.dev_account_id}:role/terraform-lab-dev-karpenter-node",
      "arn:aws:iam::${var.dev_account_id}:role/terraform-lab-eks-cluster-role",
      "arn:aws:iam::${var.dev_account_id}:role/terraform-lab-eks-node-role",
    ]

    condition {
      test     = "StringEquals"
      variable = "iam:PassedToService"
      values = [
        "ec2.amazonaws.com",
        "eks.amazonaws.com",
        "vpc-flow-logs.amazonaws.com",
      ]
    }
  }
}

resource "aws_iam_policy" "terraform_dev_platform" {
  provider    = aws.dev
  name        = "terraform-dev-platform-management"
  description = "Scoped Terraform permissions for dev ECR, EKS, EventBridge, KMS, and PassRole"
  policy      = data.aws_iam_policy_document.terraform_dev_platform.json
}

resource "aws_iam_role_policy_attachment" "terraform_dev_platform" {
  provider   = aws.dev
  role       = aws_iam_role.terraform_dev.name
  policy_arn = aws_iam_policy.terraform_dev_platform.arn
}

data "aws_iam_policy_document" "terraform_dev_iam" {
  statement {
    sid    = "IamRoleManagement"
    effect = "Allow"

    actions = [
      "iam:CreateRole",
      "iam:DeleteRole",
      "iam:GetRole",
      "iam:ListAttachedRolePolicies",
      "iam:ListRolePolicies",
      "iam:ListRoleTags",
      "iam:TagRole",
      "iam:UntagRole",
      "iam:UpdateAssumeRolePolicy",
      "iam:UpdateRole",
      "iam:UpdateRoleDescription",
    ]

    resources = local.dev_terraform_managed_role_arns
  }

  statement {
    sid    = "IamManagedPolicyManagement"
    effect = "Allow"

    actions = [
      "iam:CreatePolicy",
      "iam:CreatePolicyVersion",
      "iam:DeletePolicy",
      "iam:DeletePolicyVersion",
      "iam:GetPolicy",
      "iam:GetPolicyVersion",
      "iam:ListPolicyTags",
      "iam:ListPolicyVersions",
      "iam:SetDefaultPolicyVersion",
      "iam:TagPolicy",
      "iam:UntagPolicy",
    ]

    resources = local.dev_terraform_managed_policy_arns
  }

  statement {
    sid    = "IamInlineRolePolicyManagement"
    effect = "Allow"

    actions = [
      "iam:DeleteRolePolicy",
      "iam:GetRolePolicy",
      "iam:ListRolePolicies",
      "iam:PutRolePolicy",
    ]

    resources = local.dev_terraform_managed_role_arns
  }

  statement {
    sid    = "IamRolePolicyAttachmentManagement"
    effect = "Allow"

    actions = [
      "iam:AttachRolePolicy",
      "iam:DetachRolePolicy",
    ]

    resources = local.dev_terraform_managed_role_arns

    condition {
      test     = "ArnEquals"
      variable = "iam:PolicyARN"
      values   = local.dev_terraform_attachable_policy_arns
    }
  }

  statement {
    sid    = "IamInstanceProfileManagement"
    effect = "Allow"

    actions = [
      "iam:AddRoleToInstanceProfile",
      "iam:CreateInstanceProfile",
      "iam:DeleteInstanceProfile",
      "iam:GetInstanceProfile",
      "iam:ListInstanceProfileTags",
      "iam:RemoveRoleFromInstanceProfile",
      "iam:TagInstanceProfile",
      "iam:UntagInstanceProfile",
    ]

    resources = local.dev_terraform_managed_instance_profile_arns
  }

  statement {
    sid    = "IamEksOidcProviderManagement"
    effect = "Allow"

    actions = [
      "iam:AddClientIDToOpenIDConnectProvider",
      "iam:CreateOpenIDConnectProvider",
      "iam:DeleteOpenIDConnectProvider",
      "iam:GetOpenIDConnectProvider",
      "iam:ListOpenIDConnectProviderTags",
      "iam:RemoveClientIDFromOpenIDConnectProvider",
      "iam:TagOpenIDConnectProvider",
      "iam:UntagOpenIDConnectProvider",
      "iam:UpdateOpenIDConnectProviderThumbprint",
    ]

    resources = [
      "arn:aws:iam::${var.dev_account_id}:oidc-provider/oidc.eks.us-east-1.amazonaws.com/id/*",
    ]
  }
}

resource "aws_iam_policy" "terraform_dev_iam" {
  provider    = aws.dev
  name        = "terraform-dev-iam-management"
  description = "Scoped Terraform permissions for dev IAM roles, policies, OIDC provider, and instance profiles"
  policy      = data.aws_iam_policy_document.terraform_dev_iam.json
}

resource "aws_iam_role_policy_attachment" "terraform_dev_iam" {
  provider   = aws.dev
  role       = aws_iam_role.terraform_dev.name
  policy_arn = aws_iam_policy.terraform_dev_iam.arn
}

# Staging account — dedicated Terraform execution role
resource "aws_iam_role" "terraform_staging" {
  provider = aws.staging
  name     = "terraform-ci"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        AWS = [
          aws_iam_role.gitlab_ci.arn,
          aws_iam_role.github_actions_staging.arn,
          "arn:aws:iam::940920597829:user/terraform",
        ]
      }
      Action = "sts:AssumeRole"
    }]
  })

  tags = {
    Environment = "staging"
    ManagedBy   = "terraform"
  }
}

resource "aws_iam_role_policy_attachment" "terraform_staging" {
  for_each   = local.staging_ci_managed_policies
  provider   = aws.staging
  role       = aws_iam_role.terraform_staging.name
  policy_arn = each.value
}


# Preserve legacy GitLab Secrets Manager access in the dev account
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
        "secretsmanager:DescribeSecret",
      ]
      Resource = "arn:aws:secretsmanager:us-east-1:${var.dev_account_id}:secret:terraform-lab/*"
    }]
  })
}

# Preserve legacy GitLab Secrets Manager access in the staging account
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
        "secretsmanager:DescribeSecret",
      ]
      Resource = "arn:aws:secretsmanager:us-east-1:${var.staging_account_id}:secret:terraform-lab/*"
    }]
  })
}
