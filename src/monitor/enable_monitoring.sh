#! /bin/bash

set -e

source src/lib/initialize
source src/lib/azure/app_insights
source src/lib/azure/log_analytics

# check if app_insights is enabled for the environment 
# if yes then check app-insight instance is deployed
# if not the create it
 
logger "INFO" "Checking if app_insights is enabled for the environment ${ENV}, then deploy"
check_and_create_app_insights

logger "INFO" "Configuring Application Insights for Web App: $WEBAPP_NAME"
configure_app_insights_webapp

logger "INFO" "Configuring Application Insights for Spring App: $SPRING_APP_NAME"
configure_app_insights_spring_app

logger "INFO" "Creating Log Analytics Workspace"
# the function to check and create Log Analytics Workspace
check_and_create_log_analytics_workspace

logger "INFO" "Enable monitoring for Spring Webservice"
enable_spring_apps_monitoring

logger "INFO" "Enable monitoring for Node js Webapp"
enable_nodejs_webapp_monitoring

logger "INFO" "Linking App Insights to Log Analytics Workspace"
link_app_insights_to_log_analytics

logger "INFO" "Application Insights and Log Analytics Workspace configuration completed successfully."

