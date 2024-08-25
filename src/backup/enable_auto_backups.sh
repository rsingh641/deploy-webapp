#! /bin/bash

set -e

# Initialise the local environment
source src/lib/initialize
source src/lib/azure/backup

logger "INFO" "Setting up auto backups for webapp"
logger "INFO" "WEBAPP_BACKUP_FREQUENCY=$WEBAPP_BACKUP_FREQUENCY"

setup_auto_backup_webapp

logger "INFO" "Successsfully setup auto backups for webapp"

