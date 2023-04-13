#!/bin/bash
# Import standard library
source /var/lib/jumppad/functions.sh

# Test functions below can be uncommented to test success, failure and tracing
# success_and_exit
# failure_and_exit "intentional error"
# source test_trace.sh

# Is the terraform binary present?
hash terraform || failure_and_exit "terraform binary not found on the PATH"

# Get the latest version of terraform
TERRAFORM_VERSIONS=$(curl --fail --silent --show-error https://releases.hashicorp.com/terraform/index.json)
LATEST=$(echo $TERRAFORM_VERSIONS | \
  jq -r '.versions 
    | keys 
    | map(select(.|test("^[0-9]{1,}.[0-9]{1,}.[0-9]{1,}$")))
    | sort | reverse | first'
)

# Get the installed version of terraform
TERRAFORM_VERSION_OUTPUT=$(terraform version)
INSTALLED=$(echo $TERRAFORM_VERSION_OUTPUT | sed -r 's|Terraform v([0-9]+\.[0-9]+\.[0-9]+).*|\1|')

# Is the installed version the latest version?
if [[ $INSTALLED != $LATEST ]]; then
  failure_and_exit "terraform binary is not the latest version"
fi

# Is the 'terraform version' command used?
command_executed "terraform version" || failure_and_exit "'terraform version' command was not used to validate the installed version"

# Is the 'terraform help' command used?
command_executed "terraform help" || failure_and_exit "'terraform help' command was not used to validate the installed version"

# If we made it this far, the solution is valid
success_and_exit