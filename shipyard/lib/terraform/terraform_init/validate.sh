#!/bin/bash
# Import standard library
source /var/lib/jumppad/functions.sh

# Is the 'terraform init' command used?
command_executed "terraform init" || failure_and_exit "'terraform init' command was not used to initialize the working directory"

# Is the terraform dependency lock file created?
file_exists "$HOME/terraform_basics/.terraform.lock.hcl" || failure_and_exit "'.terraform.lock.hcl' file does not exist"

# Is the docker provider initialized?
file_contains $HOME/terraform_basics/.terraform.lock.hcl 'provider "registry.terraform.io/kreuzwerker/docker" {' || failure_and_exit "the docker provider was not correctly initialized"

# Alternative check
# Is the docker provider initialized?
# TERRAFORM_PROVIDER_PRESENT=$(terraform -chdir="$HOME/terraform_basics" providers schema -json \
# | jq '.provider_schemas | has("registry.terraform.io/kreuzwerker/docker")')
# if [[ $TERRAFORM_PROVIDER_PRESENT != "true" ]]; then
#   failure_and_exit "the docker provider was not correctly initialized"
# fi

# If we made it this far, the solution is valid
success_and_exit