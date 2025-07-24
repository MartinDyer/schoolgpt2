#!/bin/bash
set -e

# Load values from terraform.tfvars (or set manually)
TFVARS_FILE="$(dirname "$0")/terraform.tfvars"
ACR_NAME=$(grep '^acr_name' "$TFVARS_FILE" | awk -F'=' '{print $2}' | tr -d '" ')
KEYVAULT_NAME=$(grep '^key_vault_name' "$TFVARS_FILE" | awk -F'=' '{print $2}' | tr -d '" ')

# Get ACR credentials
ACR_USERNAME=$(az acr credential show --name $ACR_NAME --query "username" -o tsv)
ACR_PASSWORD=$(az acr credential show --name $ACR_NAME --query "passwords[0].value" -o tsv)

# Store in Key Vault
az keyvault secret set --vault-name $KEYVAULT_NAME --name acr-username --value "$ACR_USERNAME"
az keyvault secret set --vault-name $KEYVAULT_NAME --name acr-password --value "$ACR_PASSWORD"

echo "ACR credentials stored in Key Vault: $KEYVAULT_NAME" 