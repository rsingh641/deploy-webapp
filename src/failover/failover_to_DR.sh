#! /bin/bash

set -e

# Initialise the local environment
source src/lib/initialize
source src/lib/azure/failover

logger "INFO" "Starting to failover from Production to DR..."

switch_traffic_to_dr

logger "INFO" "Traffic switched successfully to DR."
