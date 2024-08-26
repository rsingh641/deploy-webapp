#! /bin/bash

set -e

source src/lib/initialize
source src/lib/ui/ui_manage

logger "INFO" "Updating UI Webapp service plan settings"
update_app_service_plan

logger "INFO" "Updating UI Webapp settings"
update_webapp
