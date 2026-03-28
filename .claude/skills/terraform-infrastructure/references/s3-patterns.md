# S3 Terraform Patterns

Common patterns for S3 bucket configuration in this codebase.

## Reference Existing Bucket

Buckets are typically created externally. Use data source to reference:

```hcl
data "aws_s3_bucket" "bucket" {
  bucket = var.bucket_name
}

# Use in other resources
resource "aws_s3_bucket_lifecycle_configuration" "lifecycle" {
  bucket = data.aws_s3_bucket.bucket.id
  # ...
}
```

---

## Lifecycle Configuration

Auto-expire objects after N days:

```hcl
resource "aws_s3_bucket_lifecycle_configuration" "lifecycle" {
  bucket = data.aws_s3_bucket.bucket.id

  rule {
    id     = "cleanup-temp-files"
    status = "Enabled"

    filter {
      prefix = "temp/"  # Only affects objects with this prefix
    }

    expiration {
      days = 1  # Delete after 1 day
    }
  }
}
```

### Multiple Rules

```hcl
resource "aws_s3_bucket_lifecycle_configuration" "lifecycle" {
  bucket = data.aws_s3_bucket.bucket.id

  rule {
    id     = "cleanup-temp-downloads"
    status = "Enabled"
    filter { prefix = "temp/downloads/" }
    expiration { days = 1 }
  }

  rule {
    id     = "cleanup-old-logs"
    status = "Enabled"
    filter { prefix = "logs/" }
    expiration { days = 30 }
  }
}
```

---

## CORS Configuration

For presigned URL uploads:

```hcl
resource "aws_s3_bucket_cors_configuration" "cors" {
  bucket = data.aws_s3_bucket.bucket.id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["PUT", "GET"]
    allowed_origins = var.cors_allowed_origins
    expose_headers  = ["ETag", "x-amz-request-id", "x-amz-version-id"]
    max_age_seconds = 3600  # 1 hour
  }
}
```

### Environment-Specific Origins

```hcl
locals {
  cors_origins = {
    dev = [
      "http://localhost:3000",
      "http://localhost:3001",
      "https://detections.dev.s2s.ai"
    ]
    prod = [
      "https://detections.ai",
      "https://app.detections.ai"
    ]
  }
}

resource "aws_s3_bucket_cors_configuration" "cors" {
  bucket = data.aws_s3_bucket.bucket.id

  cors_rule {
    allowed_origins = local.cors_origins[var.environment]
    # ...
  }
}
```

---

## Verification Commands

```bash
# Check lifecycle configuration
aws s3api get-bucket-lifecycle-configuration --bucket $BUCKET_NAME

# Check CORS configuration
aws s3api get-bucket-cors --bucket $BUCKET_NAME

# Test CORS preflight
curl -X OPTIONS \
  -H "Origin: http://localhost:3000" \
  -H "Access-Control-Request-Method: PUT" \
  "https://$BUCKET_NAME.s3.us-west-2.amazonaws.com/"
```

---

## S3 Path Handling

When working with S3 paths in application code, see the [s3-path-handling skill](../../s3-path-handling/SKILL.md) for:

- Parsing S3 URIs vs plain keys
- File existence checks before operations
- Configuration patterns for bucket names
