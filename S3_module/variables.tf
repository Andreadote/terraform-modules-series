variable "aws_s3_bucket" {
  type    = string
  default = "dev"

}
variable "aws_region" {
  type    = string
  default = "us-west-2"
}
variable "bucket_versioning" {
  type    = string
  default = "enabled"
}
