# Account IDs
MGMT_ACCOUNT = 940920597829
DEV_ACCOUNT = 446598504905
STAGING_ACCOUNT = 916292310732

# Resource names
DYNAMODB_TABLE = terraform-state-lock
REGION = us-east-1

# State bucket per account
MGMT_BUCKET = terraform-state-$(MGMT_ACCOUNT)
DEV_BUCKET = terraform-state-$(DEV_ACCOUNT)
STAGING_BUCKET = terraform-state-$(STAGING_ACCOUNT)

# Bootstrap management account
bootstrap-mgmt:
	aws s3api create-bucket --bucket $(MGMT_BUCKET) --region $(REGION)
	aws s3api put-bucket-versioning --bucket $(MGMT_BUCKET) --versioning-configuration Status=Enabled
	aws s3api put-bucket-encryption --bucket $(MGMT_BUCKET) --server-side-encryption-configuration '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}'
	aws dynamodb create-table --table-name $(DYNAMODB_TABLE) --attribute-definitions AttributeName=LockID,AttributeType=S --key-schema AttributeName=LockID,KeyType=HASH --billing-mode PAY_PER_REQUEST --region $(REGION)
	@echo "Management bootstrap complete!"

# Bootstrap dev account
bootstrap-dev:
	aws s3api create-bucket --bucket $(DEV_BUCKET) --region $(REGION) --profile dev
	aws s3api put-bucket-versioning --bucket $(DEV_BUCKET) --versioning-configuration Status=Enabled --profile dev
	aws s3api put-bucket-encryption --bucket $(DEV_BUCKET) --server-side-encryption-configuration '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}' --profile dev
	aws dynamodb create-table --table-name $(DYNAMODB_TABLE) --attribute-definitions AttributeName=LockID,AttributeType=S --key-schema AttributeName=LockID,KeyType=HASH --billing-mode PAY_PER_REQUEST --region $(REGION) --profile dev
	@echo "Dev bootstrap complete!"

# Bootstrap staging account
bootstrap-staging:
	aws s3api create-bucket --bucket $(STAGING_BUCKET) --region $(REGION) --profile staging
	aws s3api put-bucket-versioning --bucket $(STAGING_BUCKET) --versioning-configuration Status=Enabled --profile staging
	aws s3api put-bucket-encryption --bucket $(STAGING_BUCKET) --server-side-encryption-configuration '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}' --profile staging
	aws dynamodb create-table --table-name $(DYNAMODB_TABLE) --attribute-definitions AttributeName=LockID,AttributeType=S --key-schema AttributeName=LockID,KeyType=HASH --billing-mode PAY_PER_REQUEST --region $(REGION) --profile staging
	@echo "Staging bootstrap complete!"

# Bootstrap all accounts at once
bootstrap-all: bootstrap-mgmt bootstrap-dev bootstrap-staging
	@echo "All accounts bootstrapped!"

# Destroy backends
destroy-backend-mgmt:
	aws s3 rb s3://$(MGMT_BUCKET) --force
	aws dynamodb delete-table --table-name $(DYNAMODB_TABLE) --region $(REGION)

destroy-backend-dev:
	aws s3 rb s3://$(DEV_BUCKET) --force --profile dev
	aws dynamodb delete-table --table-name $(DYNAMODB_TABLE) --region $(REGION) --profile dev

destroy-backend-staging:
	aws s3 rb s3://$(STAGING_BUCKET) --force --profile staging
	aws dynamodb delete-table --table-name $(DYNAMODB_TABLE) --region $(REGION) --profile staging

destroy-all-backends: destroy-backend-mgmt destroy-backend-dev destroy-backend-staging
	@echo "All backends destroyed!"

# Terraform commands
init:
	terraform init

plan:
	terraform plan

apply:
	terraform apply

destroy:
	terraform destroy

fmt:
	terraform fmt -recursive

validate:
	terraform validate

# Workspace commands
workspace-dev:
	terraform workspace select dev || terraform workspace new dev

workspace-staging:
	terraform workspace select staging || terraform workspace new staging

workspace-prod:
	terraform workspace select prod || terraform workspace new prod 

# Dev environment
init-dev:
	cd environments/dev && terraform init

plan-dev:
	cd environments/dev && terraform plan

apply-dev:
	cd environments/dev && terraform apply

destroy-dev:
	cd environments/dev && terraform destroy

# Staging environment
init-staging:
	cd environments/staging && terraform init

plan-staging:
	cd environments/staging && terraform plan

apply-staging:
	cd environments/staging && terraform apply

destroy-staging:
	cd environments/staging && terraform destroy

.PHONY: bootstrap-mgmt bootstrap-dev bootstrap-staging bootstrap-all destroy-backend-mgmt destroy-backend-dev destroy-backend-staging destroy-all-backends init plan apply destroy fmt validate workspace-dev workspace-staging workspace-prod