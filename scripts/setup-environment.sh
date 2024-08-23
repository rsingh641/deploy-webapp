#! /bin/bash

set -e

if [ -z $ENV ]; then ENV=$APP_ENVIRONMENT; fi

SECRETS_FILE="config/environments/${ENV}/secrets.enc.yaml"

PROPERTIES_FILE="config/environments/${ENV}/${ENV}.properties"

source ${PROPERTIES_FILE}
source utils.sh

logger "INFO" "Authenticating to Azure"
az_login

logger "INFO" "Reading secrets from encrypted file"
fetch_secrets $SECRETS_FILE

# check if keyvault exists, if not create it
check_create_key_vault

logger "INFO" "Setting up environment for [$ENV]"

logger "INFO" "Setting up environment for [$ENV]"




