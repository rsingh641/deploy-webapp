#! /bin/bash
# This script creates the Azure Front door for Global DNS routing 

# Set error handling to exit the script immediately if a command fails
set -e

# Initialise the local environment
source src/lib/initialize
source src/lib/azure/frontdoor

logger "INFO" "Starting to deploy frontdoor resources in resource group $FRONT_DOOR_RESOURCE_GROUP"

logger "INFO" "Check and create resources group"
# Create seperate resource group for azure front door resources 
check_and_create_resource_group "$FRONT_DOOR_RESOURCE_GROUP"

logger "INFO" "Creating Front door instance"
create_front_door

logger "INFO" "Creating Front door endpoint"
create_frontend_endpoint

logger "INFO" "Creating Front door backend pool"
create_backend_pool

logger "INFO" "Adding backend to pool"
add_backend_to_pool 

logger "INFO" "Creating routing rule in front door"
create_routing_rule

logger "INFO" "Integrating traffic manager with front door"
integrate_traffic_manager_with_front_door 

logger "INFO" "Verifying the traffic manager and front door configuration"
verify_configuration

logger "INFO" "Successfully deployed and configured Azure front door with Traffic manager"

