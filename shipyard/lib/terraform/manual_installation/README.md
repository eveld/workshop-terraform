# Manual installation

The command line interface to Terraform is the terraform command, which accepts a variety of subcommands such as terraform init or terraform plan.
We refer to the `terraform` command line tool as "Terraform CLI". This terminology is often used to distinguish it from other components you might use in the Terraform product family, such as Terraform Cloud or the various Terraform providers, which are developed and released separately from Terraform CLI.

To get specific help for any specific command, use the `-help` option with the relevant subcommand. For example, to see help about the "validate" subcommand you can run `terraform validate -help`. 

## Instructions

Install the latest version of Terraform for Linux (AMD64) by downloading it from the [downloads](https://developer.hashicorp.com/terraform/downloads?product_intent=terraform) page and installing it on the PATH.

Verify that the `terraform` binary is executable and check that it is the correct version by running `terraform version`.

Use the `terraform help` command to explore the possibilities of the Terraform CLI.
