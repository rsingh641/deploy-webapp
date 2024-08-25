#! /bin/bash

set -e

source src/lib/initialize
source src/lib/azure/app_insights

# check if app_insights is enabled for the environment 
# if yes then check app-insight instance is deployed
# if not the create it
 
logger "INFO" "Checking if app_insights is enabled for the environment ${ENV}, then deploy"
check_and_create_app_insights

logger "INFO" "Configuring Application Insights for Web App: $WEBAPP_NAME"
configure_app_insights_webapp

logger "INFO" "Configuring Application Insights for Spring App: $SPRING_APP_NAME"
configure_app_insights_spring_app

logger "INFO" "Application Insights configuration completed successfully."
