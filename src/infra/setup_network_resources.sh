#! /bin/bash

# This script creates the necessary Network resources in Azure cloud infrastructure for application

set -e

# Initialise the local environment
source src/lib/initialize
source src/lib/azure/network

# Create NSGs
logger "INFO" "Creating NSG for Webapp"
create_nsg $RESOURCE_GROUP $WEBAPP_NSG_NAME $LOCATION

logger "INFO" "Creating NSG for Webservice"
create_nsg $RESOURCE_GROUP $SPRING_APP_NSG_NAME $LOCATION

# Associate NSGs with subnets
logger "INFO" "Associating NSG with Webapp subnet $WEBAPP_SUBNET_NAME"
associate_nsg_with_subnet $RESOURCE_GROUP $WEBAPP_NSG_NAME $WEBAPP_VNET $WEBAPP_SUBNET_NAME

logger "INFO" "Associating NSG with Webservice subnet $WEBSERVICE_SUBNET_NAME"
associate_nsg_with_subnet $RESOURCE_GROUP $SPRING_APP_NSG_NAME $SPRING_APP_VNET $WEBSERVICE_SUBNET_NAME

# Example rule for allowing HTTP traffic on port 80
logger "INFO" "Create NSG rule in $WEBAPP_NSG_NAME to allow traffic"
create_nsg_rule $RESOURCE_GROUP $WEBAPP_NSG_NAME "Allow-HTTP" 100 "Inbound" "Allow" "Tcp" "*" "80" "*" "*"

logger "INFO" "Create NSG rule in $SPRING_APP_NSG_NAME to allow traffic"
create_nsg_rule $RESOURCE_GROUP $SPRING_APP_NSG_NAME "Allow-HTTP" 100 "Inbound" "Allow" "Tcp" "*" "80" "*" "*"

logger "INFO" "NSG creation and subnet association completed."
