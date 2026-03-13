###############################################################################
# AWS S3 Bucket - Checkov Policy Reference
#
# ✅ VALID   = Compliant with Checkov policy
# ❌ INVALID = Violates Checkov policy (commented out)
###############################################################################

###############################################################################
# CKV2_AWS_62 - force_destroy
###############################################################################

resource "aws_s3_bucket" "main" {
  bucket        = "my-company-app-data-prod"
  force_destroy = false # ✅ CKV2_AWS_62: protects against accidental deletion
  # force_destroy = true  # ❌ CKV2_AWS_62: allows wiping all objects on destroy

  tags = {
    Name        = "my-company-app-data-prod"
    Environment = "prod"
    ManagedBy   = "terraform"
  }
}

###############################################################################
# CKV_AWS_53 / CKV_AWS_54 / CKV_AWS_55 / CKV_AWS_56 - Public Access Block
###############################################################################

resource "aws_s3_bucket_public_access_block" "main" {
  bucket = aws_s3_bucket.main.id

  block_public_acls       = true  # ✅ CKV_AWS_53
  block_public_policy     = true  # ✅ CKV_AWS_54
  ignore_public_acls      = true  # ✅ CKV_AWS_55
  restrict_public_buckets = true  # ✅ CKV_AWS_56

  # block_public_acls       = false  # ❌ CKV_AWS_53
  # block_public_policy     = false  # ❌ CKV_AWS_54
  # ignore_public_acls      = false  # ❌ CKV_AWS_55
  # restrict_public_buckets = false  # ❌ CKV_AWS_56
}

###############################################################################
# CKV_AWS_21 - Versioning
###############################################################################

resource "aws_s3_bucket_versioning" "main" {
  bucket = aws_s3_bucket.main.id

  versioning_configuration {
    status = "Enabled"   # ✅ CKV_AWS_21
    # status = "Suspended"  # ❌ CKV_AWS_21: disables versioning for new objects
    # status = "Disabled"   # ❌ CKV_AWS_21
  }
}

###############################################################################
# CKV_AWS_19 / CKV_AWS_145 - Server-Side Encryption
###############################################################################

resource "aws_s3_bucket_server_side_encryption_configuration" "main" {
  bucket = aws_s3_bucket.main.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"                                              # ✅ CKV_AWS_145: KMS encryption
      kms_master_key_id = "arn:aws:kms:us-east-1:123456789012:key/my-key-id"   # ✅ CKV_AWS_145: customer-managed key

      # sse_algorithm     = "AES256"  # ❌ CKV_AWS_145: SSE-S3, AWS-managed key, no customer control
      # kms_master_key_id omitted     # ❌ CKV_AWS_145: defaults to aws/s3 managed key
    }
    bucket_key_enabled = true # ✅ reduces KMS API call costs
  }
}

###############################################################################
# CKV_AWS_18 - Access Logging
###############################################################################

resource "aws_s3_bucket" "log_bucket" {
  bucket = "my-company-s3-access-logs"
}

resource "aws_s3_bucket_public_access_block" "log_bucket" {
  bucket                  = aws_s3_bucket.log_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_logging" "main" {
  bucket        = aws_s3_bucket.main.id
  target_bucket = aws_s3_bucket.log_bucket.id                    # ✅ CKV_AWS_18: logging enabled
  target_prefix = "my-company-app-data-prod/access-logs/"

  # Omitting this resource entirely                              # ❌ CKV_AWS_18: no access logging
}

###############################################################################
# CKV_AWS_70 / CKV2_AWS_6 / CKV_AWS_135 - Bucket Policy
###############################################################################

resource "aws_s3_bucket_policy" "main" {
  bucket     = aws_s3_bucket.main.id
  depends_on = [aws_s3_bucket_public_access_block.main]

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowAppRole"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::123456789012:role/my-app-role"  # ✅ CKV_AWS_70: specific principal
          # AWS = "*"                                          # ❌ CKV_AWS_70 / CKV2_AWS_6: wildcard grants public access
        }
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          # "s3:*"  # ❌ CKV_AWS_70: overly broad permissions
        ]
        Resource = [
          "arn:aws:s3:::my-company-app-data-prod",
          "arn:aws:s3:::my-company-app-data-prod/*"
        ]
      },
      {
        # ✅ CKV_AWS_135: enforce HTTPS only - deny all plain HTTP requests
        # Omitting this statement entirely                     # ❌ CKV_AWS_135: allows plain HTTP
        Sid       = "DenyNonTLS"
        Effect    = "Deny"
        Principal = { AWS = "*" }
        Action    = ["s3:*"]
        Resource = [
          "arn:aws:s3:::my-company-app-data-prod",
          "arn:aws:s3:::my-company-app-data-prod/*"
        ]
        Condition = {
          Bool = { "aws:SecureTransport" = "false" }
        }
      }
    ]
  })
}

###############################################################################
# CKV_AWS_300 - Lifecycle / Abort Incomplete Multipart Uploads
###############################################################################

resource "aws_s3_bucket_lifecycle_configuration" "main" {
  bucket     = aws_s3_bucket.main.id
  depends_on = [aws_s3_bucket_versioning.main]

  rule {
    id     = "main-lifecycle"
    status = "Enabled"

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = 90
      storage_class = "GLACIER"
    }

    expiration {
      days = 365
    }

    noncurrent_version_expiration {
      noncurrent_days = 90
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7  # ✅ CKV_AWS_300: cleans up failed multipart uploads
      # Omitting this block      # ❌ CKV_AWS_300: incomplete uploads accumulate cost/risk
    }
  }
}

###############################################################################
# CKV2_AWS_47 - CORS (if applicable)
###############################################################################

resource "aws_s3_bucket_cors_configuration" "main" {
  bucket = aws_s3_bucket.main.id

  cors_rule {
    allowed_origins = ["https://app.mycompany.com"]  # ✅ CKV2_AWS_47: specific origin
    # allowed_origins = ["*"]                         # ❌ CKV2_AWS_47: wildcard allows any site
    allowed_methods = ["GET", "PUT"]
    allowed_headers = ["Authorization", "Content-Type"]
    max_age_seconds = 3600
  }
}
