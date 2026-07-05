# CLAUDE.md

## Repository Purpose

This repository manages an AWS EKS Terraform platform with multi-account separation, reusable modules, remote state, CI identity federation, and cross-account Terraform role assumption.

## Read Before Editing

Before editing, read:

- `CLAUDE.md`
- `README.md`
- `git status`
- `git diff`
- Relevant Terraform files
- Backend configuration
- Provider configuration
- Bootstrap IAM and OIDC configuration
- Existing plan output when available
- `terraform state list` when state-related questions arise

Do not start editing until you understand the current worktree and whether changes are already in progress.

## Repository Rules

- Make one focused change at a time.
- Work one environment at a time.
- Do not modify dev and staging together unless explicitly requested.
- Preserve GitLab support until GitHub Actions is verified.
- Do not modify unrelated files.
- Do not rename Terraform resources casually.
- Check state impact before renaming or moving resources.
- Do not change backend keys casually.
- Do not change state bucket configuration without understanding migration impact.
- Do not add broad wildcard IAM permissions without justification.
- Prefer customer-managed policies.
- Prefer explicit actions.
- Restrict `iam:PassRole`.
- Use `allowed_account_ids` where appropriate.
- Never place permanent AWS credentials in code.
- Never expose secrets in documentation.
- Use placeholders in documentation.

## Terraform Safety Rules

- Never run `terraform apply` without explicit user approval.
- Never destroy infrastructure without explicit user approval.
- Always run `terraform fmt`.
- Always run `terraform validate`.
- Always run `terraform plan`.
- Use saved plans for reviewed applies.
- Stop on unexpected destroy.
- Stop on unexpected replacement.
- Explain every destroy or replacement.
- Do not assume a large add-only plan is wrong if the environment was intentionally destroyed.
- Inspect `terraform state list` before diagnosing state loss.
- Inspect the S3 state object location when backend behavior is suspicious.
- Bootstrap state and environment state are separate.
- Backend initialization happens before provider initialization.
- Backend credentials and provider credentials are separate concerns.
- Reinitialize backend after backend configuration changes.
- Do not use `-migrate-state` unless migration is intentional and understood.

## AWS Account Model

The model is:

- One management account.
- One or more child environment accounts.
- Dedicated Terraform execution role per environment.
- CI identity established in the management account.
- Cross-account assume-role into child accounts.

Do not include account IDs or ARNs in this file.

## Authentication Flow

GitHub Actions:

```text
GitHub Actions
-> GitHub OIDC role in management account
-> environment Terraform execution role
-> AWS resources
```

GitLab CI:

```text
GitLab CI
-> GitLab OIDC role in management account
-> environment Terraform execution role
-> AWS resources
```

Local workflow:

```text
authenticated local AWS session
-> environment Terraform execution role
-> AWS resources
```

Validate both backend role assumption and provider role assumption.

## File Ownership

- `bootstrap/` owns foundational IAM, OIDC, state access, and cross-account roles.
- `environments/` owns environment-specific Terraform configuration.
- `modules/` owns reusable infrastructure modules.
- `.github/workflows/` owns GitHub Actions if that directory exists.
- GitLab CI files own GitLab pipelines.
- `README.md` is human-facing documentation.
- `CLAUDE.md` is AI-agent operational guidance.

## IAM Rules

- No `AdministratorAccess` for the final execution-role design.
- Avoid service-wide wildcards.
- Use explicit actions.
- Scope resources where supported.
- Separate read, management, and pass-role permissions when useful.
- Keep trust policy separate from permissions policy.
- Restrict `iam:PassRole` to known service roles.
- Use request-tag and resource-tag conditions where appropriate.
- Validate permissions with real `terraform plan` behavior.
- Do not repeatedly redesign the same policy without evidence.

## Required Validation

Before presenting a change, provide:

- `terraform fmt`
- `terraform validate`
- `terraform plan`
- `git diff`
- Exact plan summary
- Exact files changed
- Exact resources changed
- Explanation of any destroy or replacement
- Confirmation that no unrelated infrastructure changed

## Communication Style

- Explain the intended change before editing.
- State the exact file and resource being changed.
- Make one focused change at a time.
- Avoid repeatedly changing the same design.
- Avoid unnecessary token usage.
- Avoid speculative edits.
- Stop and ask when state, account flow, or architecture is unclear.
- Do not claim success without command output.
- Do not tell the user to apply until the plan is reviewed.

## Known Current Decisions

- GitLab support remains.
- GitHub OIDC exists and migration is in progress.
- Dev uses a dedicated Terraform execution role.
- Route53 lookup in dev is read-only.
- Dev IAM uses scoped customer-managed policies.
- Staging must be reviewed separately.
- Infrastructure may be intentionally destroyed when not in use to reduce cost.
- Backend and provider authentication are separate.
- Documentation must not expose sensitive values.

## Safe Commands

Inspection:

```bash
git status
git diff
```

Formatting and bootstrap validation:

```bash
terraform fmt -recursive
terraform -chdir=bootstrap validate
terraform -chdir=bootstrap plan
```

Dev backend initialization:

```bash
terraform -chdir=environments/dev init -reconfigure \
  -backend-config="bucket=<DEV_STATE_BUCKET>" \
  -backend-config="dynamodb_table=<LOCK_TABLE>"
```

Dev validation and plan:

```bash
terraform -chdir=environments/dev validate
terraform -chdir=environments/dev plan
terraform -chdir=environments/dev state list
```

Staging backend initialization:

```bash
terraform -chdir=environments/staging init -reconfigure \
  -backend-config="bucket=<STAGING_STATE_BUCKET>" \
  -backend-config="dynamodb_table=<LOCK_TABLE>"
```

Staging validation and plan:

```bash
terraform -chdir=environments/staging validate
terraform -chdir=environments/staging plan
terraform -chdir=environments/staging state list
```

Do not include destructive commands as standard examples.

## Sensitive Data Rules

- Never write account IDs into `CLAUDE.md`.
- Never write role ARNs into `CLAUDE.md`.
- Never write access keys, secret keys, or session tokens.
- Never copy values from Terraform state into documentation.
- Never copy values from terminal credential output.
- Use placeholders.
- Scan documentation before finalizing.
