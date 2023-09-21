output "s3_tesla_bucket" {
  value = aws_s3_bucket.tesla_bucket[count.index].bucket
}