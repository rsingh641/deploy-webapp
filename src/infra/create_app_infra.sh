#! /bin/bash

# This script creates the necessary Azure cloud infrastructure for application

set -e

# Initialise the local environment
source src/lib/initialize
source src/lib/azure/keyvault
source src/lib/webservice/webservice_infra_deploy
source src/lib/webservice/webservice_app_deploy
source src/lib/ui/ui_infra_deploy
source src/lib/ui/ui_app_deploy

logger "INFO" "Starting to create the application infrstructure in Azure for ${ENV}"

# check if keyvault exists, if not create it
check_and_create_key_vault

# check if storage account exists if not create it
# and add its access key to the keyvault
create_storage_account_and_store_in_keyvault

# checking if required subnets exist, if not create them
# We are using seperate subnets for webservice, webservice runtime, UI and Application Gateway
check_and_create_subnet $WEBSERVICE_SUBNET_NAME $WEBSERVICE_SUBNET_PREFIX
check_and_create_subnet $WEBSERVICE_RUNTIME_SUBNET_NAME $WEBSERVICE_RUNTIME_SUBNET_PREFIX
check_and_create_subnet $UI_SUBNET_NAME $UI_SUBNET_PREFIX
check_and_create_subnet $APP_GATEWAY_SUBNET_NAME $APP_GATEWAY_SUBNET_PREFIX

logger "INFO" "Setting up application infrastucture for [$ENV]"

logger "INFO" "Check and Create Spring Webservice for [$ENV]"
check_and_create_spring_service_instance

logger "INFO" "Check and Create Spring app instance for [$ENV]"
check_and_create_spring_app_instance

logger "INFO" "Adding storage account to Spring app instance for [$ENV]"
add_storage_to_spring_app

logger "INFO" "Integrating Spring app instance with vnet for [$ENV]"
integrate_webapp_with_vnet

logger "INFO" "Check and Create UI Webapp service plan for [$ENV]"
check_and_create_app_service_plan

logger "INFO" "Check and Create UI Webapp instance for [$ENV]"
check_and_create_webapp

logger "INFO" "Creating application Gateway"
create_application_gateway 

logger "INFO" "Uploading DB2 certs to Keyvault"
upload_db2_certs_to_key_vault

logger "INFO" "uploading Oracle credentials to Keyvault"
store_oracle_creds_in_key_vault

logger "INFO" "Application Infra creation completed successfully for [$ENV]"

exit 0
