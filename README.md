# Terraform Lab — Multi-Account AWS Infrastructure

## Overview
Production-style AWS infrastructure using Terraform with:
- Multi-account setup (Management, Dev, Staging)
- Remote state in S3 with DynamoDB locking
- GitLab CI/CD pipeline with OIDC authentication
- Modular Terraform structure

## Architecture
AWS Organization
├── Management (940920597829) — billing, state, OIDC
├── Dev        (446598504905) — development resources
└── Staging    (916292310732) — staging resources
Each environment has:
├── VPC + subnets + internet gateway
├── Security groups
├── EC2 instance (t3.micro)
└── S3 bucket (versioned + encrypted)

## Project Structure
terraform-lab/
├── bootstrap/              # OIDC + GitLab CI IAM role
├── environments/
│   ├── dev/               # Dev environment config
│   └── staging/           # Staging environment config
├── modules/
│   ├── vpc/               # VPC, subnets, IGW, routes, SG
│   ├── ec2/               # EC2 instance, key pair
│   └── s3/                # S3 bucket, versioning, encryption
├── Makefile               # All project commands
└── .gitlab-ci.yml         # CI/CD pipeline

## Prerequisites

### 1. Tools required
- Terraform >= 1.5.7
- AWS CLI >= 2.15.0
- Git
- make

### 2. AWS accounts
- Management account with admin access
- Dev and Staging accounts created in AWS Organizations

### 3. AWS CLI profiles configured
```bash
# verify profiles work
aws sts get-caller-identity                    # management
aws sts get-caller-identity --profile dev      # dev
aws sts get-caller-identity --profile staging  # staging
```

## Setup (run once in order)

### Step 1 — Create S3 state buckets + DynamoDB lock tables
```bash
make bootstrap-all
```
Creates in each account:
- S3 bucket for Terraform state
- DynamoDB table for state locking

### Step 2 — Create OIDC provider + GitLab CI role
```bash
make bootstrap-oidc
```
Creates in management account:
- OIDC identity provider (trusts GitLab)
- IAM role `gitlab-ci-terraform` with AdminAccess
- Outputs the role ARN (used in .gitlab-ci.yml)

### Step 3 — Store SSH public key in Secrets Manager (all 3 accounts)
```bash
# management account
aws secretsmanager create-secret \
  --name "terraform-lab/ec2-public-key" \
  --secret-string "$(cat ~/.ssh/terraform-lab-key.pub)" \
  --region us-east-1

# dev account
aws secretsmanager create-secret \
  --name "terraform-lab/ec2-public-key" \
  --secret-string "$(cat ~/.ssh/terraform-lab-key.pub)" \
  --region us-east-1 \
  --profile dev

# staging account
aws secretsmanager create-secret \
  --name "terraform-lab/ec2-public-key" \
  --secret-string "$(cat ~/.ssh/terraform-lab-key.pub)" \
  --region us-east-1 \
  --profile staging
```

**2 — Fix the markdown code block** — first line says `markdown#` instead of `#`. Remove `markdown` from the very first line.

---

Fix those two things, save, then commit everything:

```bash
git add .
git commit -m "Add bootstrap secrets policies + update README"
git push
```

Paste the pipeline output from GitLab.

## Bootstrap Files
| File | Purpose |
|------|---------|
| `bootstrap/main.tf` | OIDC provider + GitLab CI IAM role |
| `bootstrap/s3_policies.tf` | Cross-account S3 state access |
| `bootstrap/secrets_policies.tf` | Cross-account Secrets Manager access |
| `bootstrap/variables.tf` | Account IDs + GitLab project path |
| `bootstrap/outputs.tf` | Role ARN + OIDC provider ARN |

### Step 4 — Initialize environments
```bash
make init-dev
make init-staging
```

### Step 5 — Deploy
```bash
# deploy to dev (or push to main — CI/CD handles it)
make apply-dev

# deploy to staging (requires manual approval in GitLab)
make apply-staging
```

## Makefile Commands

### Bootstrap
```bash
make bootstrap-all      # create S3 + DynamoDB in all accounts
make bootstrap-oidc     # create OIDC + GitLab CI role
make destroy-oidc       # destroy OIDC setup
make destroy-all-backends # destroy all S3 + DynamoDB
```

### Dev environment
```bash
make init-dev      # initialize dev
make plan-dev      # preview changes
make apply-dev     # deploy to dev
make destroy-dev   # destroy dev resources
```

### Staging environment
```bash
make init-staging      # initialize staging
make plan-staging      # preview changes
make apply-staging     # deploy to staging
make destroy-staging   # destroy staging resources
```

### Terraform utilities
```bash
make fmt       # format all .tf files
make validate  # validate all .tf files
```

## CI/CD Pipeline

Pipeline runs automatically on push to `main` branch:
push to main
↓
validate      → checks syntax for dev + staging
↓
plan-dev      → shows what will change in dev
↓
apply-dev     → automatically deploys to dev ✅
↓
plan-staging  → shows what will change in staging
↓
apply-staging → waits for manual approval 🔐
↓
deploys to staging ✅

### OIDC Authentication
Pipeline uses OIDC — no hardcoded AWS credentials:
- GitLab generates JWT token per job
- AWS verifies token via OIDC provider
- Returns temporary credentials (expire after 1 hour)
- Terraform uses credentials automatically

## Secrets Management
All secrets stored in AWS Secrets Manager under prefix `terraform-lab/`:

| Secret | Description |
|--------|-------------|
| `terraform-lab/ec2-public-key` | EC2 SSH public key |

## SSH Access
After deployment, SSH into EC2:
```bash
# get public IP
make apply-dev  # outputs public_ip after apply

# connect
ssh -i ~/.ssh/terraform-lab-key ec2-user@PUBLIC_IP
```

## Destroy Everything
```bash
# destroy infrastructure
make destroy-dev
make destroy-staging

# destroy backend (careful — deletes state)
make destroy-all-backends

# destroy OIDC
make destroy-oidc
```

## Cost Estimate
| Resource | Cost |
|----------|------|
| EC2 t3.micro | ~$0.01/hr |
| S3 state buckets | ~$0.00/hr (empty) |
| DynamoDB | ~$0.00/hr (on-demand, empty) |
| **Total** | **~$0.03/hr per environment** |

Always run `make destroy-dev` when done to stop charges.

## Modules

### VPC Module
Creates: VPC, public subnet, internet gateway, route table, security group (SSH only)

### EC2 Module  
Creates: EC2 instance (Amazon Linux 2023), key pair from Secrets Manager

### S3 Module
Creates: S3 bucket with versioning, encryption (AES256), public access blocked