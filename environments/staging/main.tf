terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region  = var.aws_region
  profile = "staging"
}

module "vpc" {
  source       = "../../modules/vpc"
  environment  = var.environment
  project_name = var.project_name
}

module "ec2" {
  source            = "../../modules/ec2"
  instance_type     = var.instance_type
  subnet_id         = module.vpc.subnet_id
  security_group_id = module.vpc.security_group_id
  environment       = var.environment
  project_name      = var.project_name
}

module "s3" {
  source       = "../../modules/s3"
  environment  = var.environment
  project_name = var.project_name
}