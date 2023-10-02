#!/bin/bash

#set -x

# Change to the "admin" directory
cd admin

# Display the AWS caller identity
echo $(aws sts get-caller-identity)
sleep 5

# Uncomment and modify the following lines as needed
# export TF_LOG="DEBUG"
# export TF_LOG_PATH="./terraform.log"
# ENV="dev"
# TF_PLAN="${ENV}.tfplan"

# Download and install tfsec
# wget https://github.com/tfsec/tfsec/releases/download/v1.28.1/tfsec-darwin-amd64
# chmod +x tfsec-darwin-amd64
# mv tfsec-darwin-amd64 /usr/local/bin/tfsec

# Remove existing Terraform directories and plan files
# [ -d .terraform ] && rm -rf .terraform
# rm -f *.tfplan

sleep 5

# Format Terraform files recursively
terraform fmt -recursive

# Initialize Terraform
terraform init

# Validate Terraform configuration
terraform validate

# Run tfsec (uncomment if needed)
# tfsec .

# Plan and apply Terraform
terraform plan
terraform apply -auto-approve

# Change to the "resources" directory
cd ../resources

# Set environment variables for Terraform
export TF_VAR_environment=dev
ENVIRONMENT="${TF_VAR_environment}"
TF_PLAN="${ENVIRONMENT}.tfplan"

# Set environment variables for Vault and AWS
export VAULT_ADDR=http://127.0.0.1:8200
export VAULT_AWS_ROLE=ec2_admin_role
export VAULT_TOKEN=$(cat ~/.vault-token)

sleep 5

unset AWS_ACCESS_KEY_ID
unset AWS_SECRET_ACCESS_KEY

sleep 5

# Get AWS credentials from Vault
export AWS_CREDS="$(vault read aws/creds/${VAULT_AWS_ROLE} -format=json)"
export AWS_ACCESS_KEY_ID="$(echo $AWS_CREDS | jq -r .data.access_key)"
export AWS_SECRET_ACCESS_KEY="$(echo $AWS_CREDS | jq -r .data.secret_key)"
export AWS_DEFAULT_REGION="us-west-2"

# Check if required AWS and environment variables are set
if [ -z "${AWS_SECRET_ACCESS_KEY}" ] || [ -z "${AWS_ACCESS_KEY_ID}" ] || [ -z "${AWS_DEFAULT_REGION}" ] || [ -z "${ENVIRONMENT}" ]; then
    echo "AWS CREDENTIALS AND DEFAULT REGION MUST BE SET!!"
    exit 1
fi
sleep 10
# Format Terraform files recursively and check for changes
terraform fmt -recursive -diff -check

# Initialize Terraform
terraform init

# Validate Terraform configuration
terraform validate

# Display the AWS caller identity
echo $(aws sts get-caller-identity)

# Generate a Terraform plan and save it to a file
terraform plan -out=${TF_PLAN}

# Convert the Terraform plan to JSON and run Checkov for static analysis
terraform show -json ${TF_PLAN} | jq '.' > ${TF_PLAN}.json
checkov -f ${TF_PLAN}.json

sleep 5

if [ ! -f "${TF_PLAN}" ]; then
    echo "The plan does not exist. Focus and work harder and smarter."
    exit 88
fi

terraform apply ${TF_PLAN}
rm -f *.tfplan*

terraform destroy -auto-approve


