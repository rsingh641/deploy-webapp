#!/bin/bash

# Variables - Update these as per your environment setup
RESOURCE_GROUP="rg-$ENV_NAME"
VAULT_NAME="kv-$ENV_NAME"
VM_NAME="vm-$ENV_NAME"   # Or App Service Name

# Managed Identity Name (for User-Assigned Identity)
IDENTITY_NAME="myManagedIdentity-$ENV_NAME"

# 1. Create a User-Assigned Managed Identity for the environment
az identity create --resource-group "$RESOURCE_GROUP" --name "$IDENTITY_NAME"

# Get the Managed Identity details
IDENTITY_ID=$(az identity show --resource-group "$RESOURCE_GROUP" --name "$IDENTITY_NAME" --query 'id' -o tsv)
PRINCIPAL_ID=$(az identity show --resource-group "$RESOURCE_GROUP" --name "$IDENTITY_NAME" --query 'principalId' -o tsv)

echo "Managed Identity Created: $IDENTITY_NAME"
echo "Identity ID: $IDENTITY_ID"
echo "Principal ID: $PRINCIPAL_ID"

# 2. Assign the Managed Identity to your VM or App Service in the environment
az vm identity assign --resource-group "$RESOURCE_GROUP" --name "$VM_NAME" --identities "$IDENTITY_ID"

# 3. Grant the Managed Identity access to the Azure Key Vault
az keyvault set-policy --name "$VAULT_NAME" --object-id "$PRINCIPAL_ID" --secret-permissions get list

echo "Managed Identity $IDENTITY_NAME has been assigned to $VM_NAME and granted access to $VAULT_NAME."
