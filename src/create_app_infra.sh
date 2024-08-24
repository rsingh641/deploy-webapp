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

# check if keyvault exists, if not create it
check_and_create_key_vault

# check if storage account exists if not create it
# and add its access key to the keyvault
create_storage_account_and_store_in_keyvault

# check if app_insights is enabled for the environment 
# if yes then check app-insight instance is deployed
# if not the create it
check_and_create_app_insights

# checking if required subnets exist, if not create them
check_and_create_subnet $WEBSERVICE_SUBNET_NAME $WEBSERVICE_SUBNET_PREFIX
check_and_create_subnet $WEBSERVICE_RUNTIME_SUBNET_NAME $WEBSERVICE_RUNTIME_SUBNET_PREFIX
check_and_create_subnet $UI_SUBNET_NAME $UI_SUBNET_PREFIX

logger "INFO" "Setting up application infrastucture for [$ENV]"

logger "INFO" "Check and Create Spring Webservice for [$ENV]"
check_and_create_spring_service_instance
check_and_create_spring_app_instance

logger "INFO" "Check and Create UI Webapp for [$ENV]"
check_and_create_app_service_plan
check_and_create_webapp

logger "INFO" "Deploying Webservice artifacts to Spring app service instance"
deploy_webservice_artifacts

logger "INFO" "Deploying UI artifacts to Webapp service instance"
deploy_ui_artifact

logger "INFO" "Deployment completed successfully for [$ENV]"

exit 0


