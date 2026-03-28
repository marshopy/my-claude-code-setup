---
name: terraform-infrastructure
description: Terraform infrastructure development for AWS resources. Use when creating, modifying, or validating Terraform configurations, adding S3 buckets, ECS task definitions, or other AWS resources. Covers module patterns, validation workflow, and environment-specific configurations.
---

# Terraform Infrastructure Development

## Overview

This skill provides guidance for Terraform infrastructure development:

- Creating and modifying Terraform configurations
- Following existing module patterns
- Validating Terraform code (format, lint, validate, plan)
- Managing environment-specific configurations (dev, qa, prod)

## When to Use This Skill

- Adding new AWS resources via Terraform
- Modifying existing infrastructure configurations
- Creating reusable Terraform modules
- Validating Terraform changes before deployment
- Debugging Terraform errors
- Questions about infrastructure patterns in this codebase

---

## Directory Structure

```
<service>/infrastructure/
├── dev/                    # Dev environment (standalone)
│   └── main.tf
├── terraform/              # Primary Terraform root
│   ├── main.tf             # Main configuration
│   ├── bg-for-qa-prod/     # QA/Prod blue-green
│   │   └── main.tf
│   └── modules/            # Reusable modules
│       ├── s3-bucket-config/
│       └── ecs-task-config/
```

Shared modules: `infrastructure/terraform/modules/`

---

## Validation Workflow

**Always validate Terraform changes before committing.**

### Quick Validation Checklist

Copy and track progress:

```
Terraform Validation:
- [ ] Step 1: Format check (terraform fmt)
- [ ] Step 2: Initialize (terraform init)
- [ ] Step 3: Validate syntax (terraform validate)
- [ ] Step 4: Plan dry-run (terraform plan)
- [ ] Step 5: Security scan (optional: tfsec)
```

### Step 1: Format Check

```bash
# Check formatting (non-destructive)
terraform fmt -check -recursive <path>

# Auto-fix formatting
terraform fmt -recursive <path>
```

### Step 2: Initialize

```bash
cd <terraform-directory>
terraform init
```

### Step 3: Validate

```bash
terraform validate
```

### Step 4: Plan

```bash
# With variables
terraform plan -var="key=value"

# With var file
terraform plan -var-file="dev.tfvars"
```

### Step 5: Security Scan (Optional)

```bash
# Using tfsec
tfsec <path>

# Using checkov
checkov -d <path>
```

---

## Module Pattern

Follow existing module conventions. See [references/module-template.md](references/module-template.md) for full template.

### Quick Module Structure

```
modules/<module-name>/
├── main.tf           # Resources
├── variables.tf      # Input variables
└── outputs.tf        # Output values
```

### Module Usage

```hcl
module "example" {
  source = "./modules/<module-name>"

  variable_1 = var.some_value
  variable_2 = "literal"
}
```

---

## Environment Configuration

### Environment-Specific Values

Use conditional expressions for environment differences:

```hcl
resource "example" "this" {
  value = var.environment == "dev" ? "dev-value" : "prod-value"
}
```

### Secrets from AWS Secrets Manager

All sensitive values come from Secrets Manager:

```hcl
secrets = [
  {
    name      = "BUCKET_NAME"
    valueFrom = "arn:aws:secretsmanager:${var.aws_region}:${var.aws_account_id}:secret:${var.secret_path}:BUCKET_NAME::"
  }
]
```

---

## Common Patterns

| Pattern | Example |
|---------|---------|
| Reference existing resource | `data "aws_s3_bucket" "bucket" { bucket = var.name }` |
| Environment variable | `var.environment == "dev" ? "x" : "y"` |
| Module source (local) | `source = "./modules/module-name"` |
| Module source (shared) | `source = "../../../../infrastructure/terraform/modules/name"` |
| Secrets ARN | `arn:aws:secretsmanager:${region}:${account}:secret:${path}:KEY::` |

---

## Files Reference

| Purpose | Location |
|---------|----------|
| Shared modules | `infrastructure/terraform/modules/` |
| Module template | [references/module-template.md](references/module-template.md) |
| S3 patterns | [references/s3-patterns.md](references/s3-patterns.md) |
| Troubleshooting | [references/troubleshooting.md](references/troubleshooting.md) |

---

## Checklists

### New Terraform Resource

- [ ] Check for existing similar resources or modules
- [ ] Create in appropriate directory (service-specific or shared module)
- [ ] Add required variables with descriptions
- [ ] Add outputs for values other resources need
- [ ] Run validation workflow (format → init → validate → plan)
- [ ] Test in dev environment first

### New Terraform Module

- [ ] Create under `modules/` directory
- [ ] Include main.tf, variables.tf, outputs.tf
- [ ] Document all variables with descriptions
- [ ] Add default values where appropriate
- [ ] Create usage example in main.tf comments
- [ ] Reference module from consuming configs
