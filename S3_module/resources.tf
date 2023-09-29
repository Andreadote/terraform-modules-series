# AWS KMS Key for server-side encryption
resource "aws_kms_key" "tesla_key" {
  description             = "Key used to encrypt bucket objects"
  deletion_window_in_days = 10
  is_enabled              = true
  enable_key_rotation     = true

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Id": "key-default-1",
  "Statement": [
    {
      "Sid": "Enable IAM User Permissions",
      "Effect": "Allow",
      "Principal": {
        "AWS": "*"
      },
      "Action": "kms:*",
      "Resource": "*"
    }
  ]
}
EOF
}

# Random integer generator for bucket naming
resource "random_integer" "tesla_bucket" {
  count = var.tesla_vpc ? 1 : 0
  min   = 1
  max   = 500

  keepers = {
    Environment = var.aws_s3_bucket
  }
}

# S3 bucket lifecycle configuration
resource "aws_s3_bucket_lifecycle_configuration" "tesla_lifecycle" {
  bucket = aws_s3_bucket.tesla_bucket[0].bucket
  rule {
    id     = "abort-incomplete-multipart-upload"
    status = "Enabled"

    abort_incomplete_multipart_upload {
      days_after_initiation = 7 # Abort incomplete multipart uploads after 7 days
    }
  }

  rule {
    id     = "example-rule"
    status = "Enabled"
    filter {
      prefix = "" # You can modify the prefix as needed
    }

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = 60
      storage_class = "GLACIER"
    }
  }
}

# S3 bucket for tesla
resource "aws_s3_bucket" "tesla_bucket" {
  count  = var.tesla_vpc ? 1 : 0
  bucket = "bootcamp32-${lower(var.aws_s3_bucket)}-${random_integer.tesla_bucket[0].result}"

  versioning {
    enabled = true
  }
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        kms_master_key_id = "alias/aws/s3"
        sse_algorithm     = "aws:kms"
      }
    }
  }

  tags = {
    Name        = "MyS3Bucket"
    Environment = "Production"
  }
}

# Event notification configuration
resource "aws_s3_bucket_lifecycle_configuration" "tesla_event_lifecycle" {
  rule {
    id     = "example-event-rule"
    status = "Enabled"

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = 60
      storage_class = "GLACIER"
    }
  }

  bucket = aws_s3_bucket.tesla_bucket[0].bucket
}

# Cross-region replication configuration for the S3 bucket
resource "aws_s3_bucket_replication_configuration" "tesla_replication" {
  role = "arn:aws:iam::109753259968:role/replica"
  rule {
    id       = "tesla-replication-rule"
    status   = "Enabled"
    priority = 1

    destination {
      bucket        = "arn:aws:s3:::elasticbeanstalk-ca-central-1-109753259968"
      storage_class = "STANDARD"
    }

    source_selection_criteria {
      sse_kms_encrypted_objects {
        status = "Enabled"
      }
    }
  }

  bucket = aws_s3_bucket.tesla_bucket[0].bucket
}

# Configure public access settings for the S3 bucket
resource "aws_s3_bucket_public_access_block" "tesla_bucket" {
  bucket = aws_s3_bucket.tesla_bucket[0].bucket

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Create the S3 bucket logging configuration
resource "aws_s3_bucket_logging" "example_logging" {
  bucket = aws_s3_bucket.tesla_bucket[0].bucket

  target_bucket = "log-bucket"
  target_prefix = "log/"
}

resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = aws_s3_bucket.tesla_bucket[0].bucket

  lambda_function {
    lambda_function_arn = "arn:aws:lambda:us-east-1:123456789012:function:my-function"
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = "uploads/"
    filter_suffix       = ".jpg"
  }
}
