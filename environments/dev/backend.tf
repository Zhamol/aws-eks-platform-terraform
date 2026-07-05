terraform {
  backend "s3" {
    # bucket and dynamodb_table are passed via -backend-config in CI
    # terraform init -backend-config="bucket=terraform-state-<account_id>" \
    #                -backend-config="dynamodb_table=terraform-state-lock"

    key     = "dev/terraform.tfstate"
    region  = "us-east-1"
    encrypt = true

    assume_role = {
      role_arn = "arn:aws:iam::446598504905:role/terraform-ci"
    }
  }
}