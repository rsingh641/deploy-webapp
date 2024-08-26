#! /bin/bash

set -e

source src/lib/initialize
source src/lib/webservice/webservice_manage

logger "INFO" "Updating Spring Webservice settings"
update_spring_app

