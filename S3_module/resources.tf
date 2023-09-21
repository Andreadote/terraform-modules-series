# AWS KMS Key for server-side encryption
resource "aws_kms_key" "tesla_key" {
  description             = "Key used to encrypt bucket objects"
  deletion_window_in_days = 10
}

# S3 bucket for tesla
resource "aws_s3_bucket" "tesla_bucket" {
  count = var.tesla_vpc ? 1 : 0
  bucket = "bootcamp32-${lower(var.aws_s3_bucket)}-${random_integer.tesla_bucket[count.index].result}"

  tags = {
    Name        = "MyS3Bucket"
    Environment = "Production"
  }
}

# Server-side encryption configuration for the S3 bucket
resource "aws_s3_bucket_server_side_encryption_configuration" "example" {
  count  = var.tesla_vpc ? 1 : 0
  bucket = aws_s3_bucket.tesla_bucket[count.index].bucket

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.tesla_key.arn
      sse_algorithm     = "aws:kms"
    }
  }
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

# S3 bucket versioning configuration
resource "aws_s3_bucket_versioning" "versioning_tesla_bucket" {
  count  = var.tesla_vpc ? 1 : 0
  bucket = aws_s3_bucket.tesla_bucket[count.index].bucket

  versioning_configuration {
    status = var.bucket_versioning
  }
}
