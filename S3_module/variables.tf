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
  default = "Enabled" # Update to "Suspended" or "Disabled" as needed
}
variable "tesla_vpc" {
  type    = bool
  default = true
}

variable "aws_access" {
  type    = string
  default = "AKIARTDON27ABQUJNYH4"
}

variable "aws_secret" {
  type    = string
  default = "rCzbKmCO9CjIfVmy9dCSQ+kRf41gzgUz1gmOgF6k"
}