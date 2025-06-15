#!/bin/bash
# Runs terraform init, plan, and extracts JSON from the plan

cd infra/terraform || exit 1
terraform init
terraform plan -out=tfplan.binary
terraform show -json tfplan.binary > ${PLAN_JSON}
terraform show -json terraform.tfstate > ${STATE_JSON}
