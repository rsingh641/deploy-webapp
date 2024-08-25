#! /bin/bash

set -e

source src/lib/initialize
source src/lib/azure/app_insights

logger "INFO" "Creating Action group to send Email and SMS alearts"
# configure the email, and phone number in env.properties file
create_action_group

logger "INFO" "Starting to enable CPU and Memory alert in the environment ${ENV}"

logger "INFO" "Creating CPU alert for ui in the environment ${ENV}"
create_cpu_alert_webapp

logger "INFO" "Creating Memory alert for ui in the environment ${ENV}"
create_memory_alert_webapp

logger "INFO" "Creating CPU alert for Webservice in the environment ${ENV}"
create_cpu_alert_spring_app

logger "INFO" "Creating Memory alert for Webservice in the environment ${ENV}"
create_memory_alert_spring_app

logger "INFO" "Completed enabling CPU and Memory alert in the environment ${ENV}"
