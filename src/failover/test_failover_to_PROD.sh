#! /bin/bash

set -e

# Initialise the local environment
source src/lib/initialize
source src/lib/azure/failover

logger "INFO" "Starting to Test failover from DR to PROD..."

test_failover_to_prod

logger "INFO" "Traffic switched successfully to PROD."

logger "INFO" "Switching traffic back to DR..."

switch_traffic_to_dr

logger "INFO" "Traffic switched successfully to DR."

