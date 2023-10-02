#!/bin/bash


set -x

export TF_LOG="DEBUG"
export TF_LOG_PATH="./terraform.log"

ENV=dev
TF_PLAN="${ENV}".tfplan


#wget https://github.com/tfsec/tfsec/releases/download/v1.28.1/tfsec-darwin-amd64
#chmod +x tfsec-darwin-amd64
#mv tfsec-darwin-amd64 /usr/local/bin/tfsec


[ -d .terraform ] && rm -rf .terraform
rm -f *.tfplan

sleep 5


# Format Terraform files recursively
terraform fmt -recursive

# Initialize Terraform
terraform init

# Validate Terraform configuration
terraform validate

#tfsec .
# Generate a Terraform plan and save it to a file
terraform plan -out=${TF_PLAN}

# Show the Terraform plan in JSON format
terraform show -json ${TF_PLAN} | jq '.' > ${TF_PLAN}.json
# Run this command on your local terminal first to install or upgrade Checkov
############  pip3 install -U checkov    #######################################

# This command will install or upgrade Checkov on your local machine,
# allowing you to use it for infrastructure as code (IaC) security scanning.

# After the installation, type 'checkov' in your local terminal to see the newest updates.

checkov -f ${TF_PLAN}.json

if [ "$?" -eq "0" ]; then
     echo "Your configuration is Awesome"
else
     echo "Your code needs some work!"
     exit 200
fi

if [ ! -f "${TF_PLAN}" ]; then
     echo "The plan does not exist******** Focus and work harder and smarter"
     exit 88
fi
