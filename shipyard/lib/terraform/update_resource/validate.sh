#!/bin/bash
# Import standard library
source /var/lib/jumppad/functions.sh

# Check that docker.tf exists
file_exists "$HOME/terraform_basics/docker.tf"

# Check that the version is updated in docker.tf
file_contains "$HOME/terraform_basics/docker.tf" "\"alpine:3.17\""
 
# Check that the terraform apply command is executed
command_executed "terraform apply" || failure_and_exit "'terraform apply' command was not used to apply changes"

# Check that the the new version is updated in the state
terraform -chdir="$HOME/terraform_basics" show -json | jq -e '.values.root_module.resources | map(select(.address == "docker_image.alpine" and .values.name == "alpine:3.17")) | length == 1' > /dev/null

# Check that the new image is pulled
docker image ls --format '{{json .}}' | jq -s -e '. | map(select(.Repository == "alpine" and .Tag == "3.17")) | length == 1' > /dev/null || failure_and_exit "the docker \"alpine\" image with tag \"3.17\" was not pulled"

# Check that the container is updated
IMAGE_ID=$(docker image inspect alpine:3.17 | jq -r '.[0].Id' | cut -d ':' -f 2 | awk '{print substr($0,1,12)}')
docker ps --format '{{json .}}' | jq -s -e --arg image "$IMAGE_ID" '. | map(select(.Image == $image and .Names == "terraform-basics" and .State == "running")) | length == 1' > /dev/null || failure_and_exit "the docker container named \"terraform-basics\" is not running"

# If we made it this far, the solution is valid
success_and_exit