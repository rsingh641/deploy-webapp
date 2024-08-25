#! /bin/bash

set -e

# Initialise the local environment
source src/lib/initialize
source src/lib/azure/backup

logger "INFO" "Taking a manual backup of webapp $WEBAPP_NAME"

manual_backup_webapp

logger "INFO" "Backup has been successfully initiated for webapp $WEBAPP_NAME"

