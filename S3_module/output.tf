output "s3_tesla_bucket_name" {
  value = aws_s3_bucket.tesla_bucket[0].bucket
}
