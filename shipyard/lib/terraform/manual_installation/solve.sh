#!/bin/bash
# Get the download url of the latest version of terraform
TERRAFORM_URL=$(curl --fail --silent --show-error https://releases.hashicorp.com/terraform/index.json | \
  jq -r '.versions 
    | map(select(.version|test("^[0-9]{1,}.[0-9]{1,}.[0-9]{1,}$"))) 
    | sort | reverse | first
    | .builds[] | select(.os=="linux" and .arch=="amd64") 
    | .url'
)

# Download the latest version of terraform
curl --fail --silent --show-error -o /tmp/terraform.zip $TERRAFORM_URL

# Move the binary to the PATH
unzip -qq -o /tmp/terraform.zip -d /usr/local/bin/