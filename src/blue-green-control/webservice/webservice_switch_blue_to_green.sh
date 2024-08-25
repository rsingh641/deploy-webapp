#! /bin/bash

set -e

source src/lib/initialize
source src/lib/webservice/webservice_manage

switch_webservice_deployment $SPRING_APP_GREEN_DEPLOYMENT_NAME

unset_webservice_deployment $SPRING_APP_BLUE_DEPLOYMENT_NAME
