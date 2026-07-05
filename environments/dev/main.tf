terraform {
  required_version = "~> 1.7"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region  = var.aws_region
  profile = "dev"

  allowed_account_ids = [
    var.account_id
  ]
}

provider "aws" {
  alias   = "management"
  region  = var.aws_region
  profile = "default"

  allowed_account_ids = [
    "940920597829"
  ]
}

module "vpc" {
  source               = "../../modules/vpc"
  environment          = var.environment
  project_name         = var.project_name
  vpc_cidr             = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  availability_zones   = var.availability_zones
}

module "ec2" {
  source            = "../../modules/ec2"
  instance_type     = var.instance_type
  subnet_id         = module.vpc.public_subnet_ids[0] # use the first public subnet
  security_group_id = module.vpc.security_group_id
  environment       = var.environment
  project_name      = var.project_name
}

module "s3" {
  source       = "../../modules/s3"
  environment  = var.environment
  project_name = var.project_name
}

module "eks" {
  source              = "../../modules/eks"
  project_name        = var.project_name
  environment         = var.environment
  private_subnet_ids  = module.vpc.private_subnet_ids
  vpc_id              = module.vpc.vpc_id
  vpc_cidr            = module.vpc.vpc_cidr
  public_access_cidrs = var.public_access_cidrs
  kubernetes_version  = var.kubernetes_version
}
# triggered

module "ecr" {
  source = "../../modules/ecr"

  repository_names = var.ecr_repository_names
  environment      = var.environment
  project_name     = var.project_name
  images_to_keep   = var.ecr_images_to_keep
}

module "route53" {
  source = "../../modules/route53"

  providers = {
    aws = aws.management
  }

  domain_name = var.domain_name
}