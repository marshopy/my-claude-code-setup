# Terraform Troubleshooting

Common issues and solutions for Terraform in this codebase.

---

## Validation Errors

### Error: Missing required provider

```
Error: Could not load plugin
```

**Solution:** Run `terraform init` first.

```bash
cd <terraform-directory>
terraform init
```

### Error: Invalid reference

```
Error: Reference to undeclared resource
```

**Solution:** Check resource name matches declaration. Common issues:
- Typo in resource name
- Resource in different module (needs module prefix)
- Data source vs resource confusion (`data.aws_s3_bucket.bucket` vs `aws_s3_bucket.bucket`)

### Error: Invalid variable value

```
Error: Invalid value for variable
```

**Solution:** Check variable type and validation constraints:

```hcl
# If validation fails
variable "environment" {
  validation {
    condition     = contains(["dev", "qa", "prod"], var.environment)
    error_message = "Environment must be dev, qa, or prod."
  }
}
```

---

## Format Errors

### Files not formatted

```
services/intel/infrastructure/terraform/main.tf
```

**Solution:** Auto-fix with:

```bash
terraform fmt -recursive services/intel/infrastructure/
```

---

## Plan/Apply Errors

### Error: Bucket not found

```
Error: error reading S3 bucket: BucketNotFound
```

**Solution:** Verify bucket exists and you have access:

```bash
aws s3 ls s3://<bucket-name>
```

If bucket doesn't exist, it needs to be created externally first.

### Error: Access Denied

```
Error: error configuring S3 bucket lifecycle: AccessDenied
```

**Solution:** Check IAM permissions. Need `s3:PutLifecycleConfiguration` permission.

### Error: State locked

```
Error: Error acquiring the state lock
```

**Solution:**
1. Wait for other operation to complete
2. If stuck, force unlock (dangerous): `terraform force-unlock <lock-id>`

---

## Module Errors

### Error: Module not found

```
Error: Module not installed
```

**Solution:** Module source path may be wrong. Check relative path:

```hcl
# Correct relative path from consuming file
source = "./modules/s3-bucket-config"

# Shared modules (from service directory)
source = "../../../../infrastructure/terraform/modules/name"
```

Then run `terraform init`.

### Error: Unsupported argument in module

```
Error: Unsupported argument "unknown_var"
```

**Solution:** Module doesn't have that variable. Check module's `variables.tf`.

---

## State Issues

### Drift detected

Plan shows changes you didn't make.

**Causes:**
- Manual changes via AWS Console/CLI
- Another process modified resource
- Terraform version differences

**Solution:**
1. Review the diff carefully
2. If manual change was intentional, update Terraform to match
3. If unintentional, let Terraform fix it

### Resource already exists

```
Error: Resource already exists
```

**Solution:** Import the existing resource:

```bash
terraform import aws_s3_bucket_lifecycle_configuration.lifecycle bucket-name
```

---

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Hardcoded account ID | Use `var.aws_account_id` |
| Hardcoded region | Use `var.aws_region` |
| Missing provider block | Add `terraform { required_providers { ... } }` |
| Wrong secret ARN format | `arn:aws:secretsmanager:${region}:${account}:secret:${path}:KEY::` |
| Path separator on Windows | Use `/` not `\` in source paths |

---

## Debug Commands

```bash
# Verbose logging
TF_LOG=DEBUG terraform plan

# Check state
terraform state list
terraform state show <resource>

# Refresh state from cloud
terraform refresh
```
