terraform {
  backend "s3" {
    bucket         = "terraform-state-916292310732"
    key            = "staging/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-state-lock"
    encrypt        = true
    profile        = "staging"
  }
}