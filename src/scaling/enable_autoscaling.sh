#! /bin/bash

set -e

source src/lib/initialize
source src/lib/azure/autoscaling

logger "INFO" "Starting autoscale setup..."

logger "INFO" "Enabling autoscale for Webapp."
# Enable autoscale for Web Apps, configure the autoscale parameters in ui.properties
enable_autoscale_webapp

logger "INFO" "Configuring metric rule based autoscaling for Webapp."
# Configure custom autoscale settings for Web Apps
# Based on metric rule configured in ui.properties
configure_metric_rule_autoscale_webapp

logger "INFO" "Enabling autoscale for Spring app."
# Enable autoscale for Web Apps, configure the autoscale parameters in ui.properties
enable_autoscale_spring_app

logger "INFO" "Configuring metric rule based autoscaling for Spring app."
# Configure custom autoscale settings for Web Apps
# Based on metric rule configured in ui.properties
configure_metric_rule_autoscale_spring_app

logger "INFO" "Autoscale enabled successfully."

