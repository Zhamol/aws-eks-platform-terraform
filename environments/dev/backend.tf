terraform {
  backend "s3" {
    bucket         = "terraform-state-446598504905"
    key            = "dev/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-state-lock"
    encrypt        = true
    profile        = "dev"
  }
}
