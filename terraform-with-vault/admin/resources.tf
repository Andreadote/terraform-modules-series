provider "vault" {
  address = var.vault_address
  token   = var.vault_token
}

resource "vault_aws_secret_backend" "aws" {
  access_key = var.access_key
  secret_key = var.secret_key
  region     = "us-west-2"

  default_lease_ttl_seconds = "120"
  max_lease_ttl_seconds     = "3600"

}

resource "vault_aws_secret_backend_role" "ec2_admin" {
  backend         = vault_aws_secret_backend.aws.path
  name            = "ec2_admin_role"
  credential_type = "iam_user"

  policy_document = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "iam:*",
        "ec2:*",
        "eks:*"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}

resource "vault_auth_backend" "aws" {
  type = "aws"
}

