#! /bin/bash

set -e

source src/lib/initialize
source src/lib/azure/autoscaling

logger "INFO" "Starting autoscale setup..."

# Enable autoscale for Web Apps, configure the autoscale parameters in ui.properties
enable_autoscale_webapp

# Configure custom autoscale settings for Web Apps
# Based on metric rule configured in ui.properties
configure_metric_rule_autoscale_webapp

# Enable autoscale for Web Apps, configure the autoscale parameters in ui.properties
enable_autoscale_spring_app

# Configure custom autoscale settings for Web Apps
# Based on metric rule configured in ui.properties
configure_metric_rule_autoscale_spring_app

logger "INFO" "Autoscale setup completed successfully."

