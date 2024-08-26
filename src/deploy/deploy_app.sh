#! /bin/bash

set -e

source src/lib/initialize
source src/lib/webservice/webservice_app_deploy
source src/lib/ui/ui_app_deploy

logger "INFO" "Starting to deploy the application in ${ENV}"

logger "INFO" "Downloading Build Artificats to local path: $LOCAL_ARTIFACT_DIR"
download_artifact

logger "INFO" "Replacing placeholders in app properties file with values from secrets file"
replace_secrets

logger "INFO" "Replacing placeholders in app properties file with values from properties file"
replace_properties

logger "INFO" "Deploying Webservice artifacts to Spring app service instance"
deploy_webservice_artifacts

logger "INFO" "Fetching DB2 certificates from Keyvault and providing to Spring app service instance"
fetch_and_provide_db2_certs

logger "INFO" "Fetching Oracle credentials from Keyvault and providing to Spring app service instance"
fetch_and_provide_oracle_creds

logger "INFO" "Deploying UI artifacts to Webapp service instance"
deploy_ui_artifact

logger "INFO" "Successfully deployed the application in ${ENV}"
