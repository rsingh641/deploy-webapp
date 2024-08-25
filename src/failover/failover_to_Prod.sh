#! /bin/bash

set -e

# Initialise the local environment
source src/lib/initialize
source src/lib/azure/failover

logger "INFO" "Starting to failover from DR to PROD..."

switch_traffic_to_prod

logger "INFO" "Traffic switched successfully to PROD."
