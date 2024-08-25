#! /bin/bash

# This script creates the necessary Network resources in Azure cloud infrastructure for application

set -e

source src/lib/initialize
source src/lib/ui/ui_infra_deploy
source src/lib/webservice/webservice_infra_deploy

# Check if the deployment flag is not set or is set to "false"
if [ -z "${DEPLOYMENT_MODEL_BLUE_GREEN}" ] || [ "${DEPLOYMENT_MODEL_BLUE_GREEN}" == "false" ]; then
    logger "INFO" "Skipping deployment for Blue/Green Deployment Model as its not enabled..."
    exit 0
fi

logger "INFO" "Deploying resources for Blue/Green Deployment Model..."

logger "INFO" "Creating Webapp deployment slot - $WEBAPP_SLOT_BLUE"
create_webapp_deployment_slot $WEBAPP_SLOT_BLUE

logger "INFO" "Creating Webapp deployment slot - $WEBAPP_SLOT_GREEN"
create_webapp_deployment_slot $WEBAPP_SLOT_GREEN

logger "INFO" "Creating Spring Webservice deployment - $SPRING_APP_BLUE_DEPLOYMENT_NAME"
create_spring_app_deployment $SPRING_APP_BLUE_DEPLOYMENT_NAME

logger "INFO" "Creating Spring Webservice deployment - $SPRING_APP_GREEN_DEPLOYMENT_NAME"
create_spring_app_deployment $SPRING_APP_GREEN_DEPLOYMENT_NAME

logger "INFO" "Primary deployment instance for webapp is - $WEBAPP_SLOT"

logger "INFO" "Primary deployment instance for spring webservice is - $SPRING_APP_DEPLOYMENT_NAME"

logger "INFO" "Successfully deployed resources for Blue/Green Deployment Model..."
