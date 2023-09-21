output "s3_tesla_bucket_name" {
  value = var.tesla_vpc ? aws_s3_bucket.tesla_bucket[0].bucket : null
}
