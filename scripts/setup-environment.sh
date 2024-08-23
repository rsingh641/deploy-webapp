#! /bin/bash

set -e

if [ -z $ENV ]; then ENV=$APP_ENVIRONMENT; fi

SECRETS_FILE="config/environments/${ENV}/secrets.enc.yaml"

PROPERTIES_FILE="config/environments/${ENV}/${ENV}.properties"

source ${PROPERTIES_FILE}
source helper.sh

check_az_cli

logger "INFO" "Authenticating to Azure"
az_login

logger "INFO" "Reading secrets from encrypted file"
fetch_secrets $SECRETS_FILE

# check if keyvault exists, if not create it
check_and_create_key_vault

# check if storage account exists
create_storage_account_and_store_in_keyvault

# check if app_insights is deployed
check_and_create_app_insights

# checking if required subnets exist, if not create them
check_and_create_subnet $WEBSERVICE_SUBNET_NAME $WEBSERVICE_SUBNET_PREFIX
check_and_create_subnet $WEBSERVICE_RUNTIME_SUBNET_NAME $WEBSERVICE_RUNTIME_SUBNET_PREFIX
check_and_create_subnet $UI_SUBNET_NAME $UI_SUBNET_PREFIX

logger "INFO" "Setting up Applications for [$ENV]"


./deploy-webservice-spring.sh





