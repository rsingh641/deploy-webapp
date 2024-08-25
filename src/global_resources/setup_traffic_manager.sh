#! /bin/bash
# This script creates the necessary Azure cloud infrastructure for 
# disaster recovery and failover to another environment

# Set error handling to exit the script immediately if a command fails
set -e

# Initialise the local environment
source src/lib/initialize
source src/lib/azure/traffic_manager

logger "INFO" "Starting to deploy traffic manager resources in resource group $TRAFFIC_MANAGER_RESOURCE_GROUP"

# Create seperate resource group for traffic manager resources 
check_and_create_resource_group "$TRAFFIC_MANAGER_RESOURCE_GROUP"

# Create Traffic Manager profile in the chosen resource group
create_traffic_manager_profile "$TRAFFIC_MANAGER_PROFILE" "$TRAFFIC_MANAGER_RESOURCE_GROUP"

# Add production and DR endpoints
add_traffic_manager_endpoint "$TRAFFIC_MANAGER_PROD_ENDPOINT_NAME" "$PROD_ENDPOINT" "$PROD_PRIORITY"
add_traffic_manager_endpoint "$TRAFFIC_MANAGER_DR_ENDPOINT_NAME" "$DR_ENDPOINT" "$DR_PRIORITY"

# Configure health probes
update_traffic_manager_health_probes "$HEALTH_CHECK_PATH" $HEALTH_CHECK_PORT

logger "INFO" "Successfully created and configured health check and traffic manager configuration"

