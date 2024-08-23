#! /bin/bash

set -e

# Initialise the local environment
source initialize

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





