# Terraform Module Template

Use this template when creating new Terraform modules.

## Directory Structure

```
modules/<module-name>/
├── main.tf           # Core resources
├── variables.tf      # Input variables
└── outputs.tf        # Output values
```

---

## main.tf Template

```hcl
# Module: <module-name>
# Description: <brief description>
#
# Usage:
#   module "example" {
#     source = "./modules/<module-name>"
#
#     required_var = "value"
#     optional_var = "override"
#   }

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# =======================
# Data Sources
# =======================
# Reference existing resources here
# data "aws_s3_bucket" "bucket" {
#   bucket = var.bucket_name
# }

# =======================
# Resources
# =======================
# Define managed resources here
# resource "aws_s3_bucket_lifecycle_configuration" "lifecycle" {
#   bucket = data.aws_s3_bucket.bucket.id
#
#   rule {
#     id     = "rule-name"
#     status = "Enabled"
#     ...
#   }
# }
```

---

## variables.tf Template

```hcl
# =======================
# Required Variables
# =======================
variable "required_var" {
  description = "Clear description of what this variable is for"
  type        = string
  # No default = required
}

# =======================
# Optional Variables
# =======================
variable "optional_var" {
  description = "Clear description with default behavior"
  type        = string
  default     = "default-value"
}

variable "environment" {
  description = "Deployment environment (dev, qa, prod)"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "qa", "prod"], var.environment)
    error_message = "Environment must be dev, qa, or prod."
  }
}

variable "tags" {
  description = "Additional tags to apply to resources"
  type        = map(string)
  default     = {}
}
```

---

## outputs.tf Template

```hcl
output "resource_arn" {
  description = "ARN of the created/configured resource"
  value       = aws_resource.this.arn
}

output "resource_id" {
  description = "ID of the created/configured resource"
  value       = aws_resource.this.id
}
```

---

## Variable Types Reference

| Type | Example |
|------|---------|
| string | `type = string` |
| number | `type = number` |
| bool | `type = bool` |
| list(string) | `type = list(string)` |
| map(string) | `type = map(string)` |
| object | `type = object({ key = string, value = number })` |

---

## Conventions

1. **Provider version**: Use `~> 5.0` for AWS provider
2. **Resource naming**: Use `this` for the primary resource, descriptive names for secondary
3. **Variable descriptions**: Always include, be specific about format/constraints
4. **Validation blocks**: Add for constrained values (environments, regions)
5. **Tags**: Accept additional tags via variable, merge with defaults
6. **Comments**: Include usage example at top of main.tf
