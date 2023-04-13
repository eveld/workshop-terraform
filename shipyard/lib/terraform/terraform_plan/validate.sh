#!/bin/bash
# Import standard library
source /var/lib/jumppad/functions.sh

# Is the 'terraform plan' command used?
command_executed "terraform plan" || failure_and_exit "'terraform plan' command was not used to preview changes"

# If we made it this far, the solution is valid
success_and_exit