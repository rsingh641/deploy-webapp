#! /bin/bash

# Set error handling to exit the script immediately if a command fails
set -e

# Create Traffic Manager profile in the chosen resource group
create_traffic_manager_profile "$TRAFFIC_MANAGER_PROFILE" "$TRAFFIC_MANAGER_RESOURCE_GROUP"

# Add production and DR endpoints
add_traffic_manager_endpoint "$TRAFFIC_MANAGER_PROFILE" "$TRAFFIC_MANAGER_RESOURCE_GROUP" "$TRAFFIC_MANAGER_PROD_ENDPOINT_NAME" "$PROD_ENDPOINT" "$PROD_PRIORITY"
add_traffic_manager_endpoint "$TRAFFIC_MANAGER_PROFILE" "$TRAFFIC_MANAGER_RESOURCE_GROUP" "$TRAFFIC_MANAGER_DR_ENDPOINT_NAME" "$DR_ENDPOINT" "$DR_PRIORITY"

# Configure health probes
update_traffic_manager_health_probes "$TRAFFIC_MANAGER_PROFILE" "$TRAFFIC_MANAGER_RESOURCE_GROUP" "$HEALTH_CHECK_PATH" $HEALTH_CHECK_PORT

