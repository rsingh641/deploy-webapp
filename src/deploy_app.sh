#! /bin/bash

set -e

source src/lib/initialize

logger "INFO" "Downloading Build Artificats to local path: $LOCAL_ARTIFACT_DIR"
download_artifact

logger "INFO" "Replacing placeholders in app properties file with values from secrets file"
replace_secrets

logger "INFO" "Replacing placeholders in app properties file with values from properties file"
replace_properties

logger "INFO" "Deploying Webservice artifacts to Spring app service instance"
deploy_webservice_artifacts

logger "INFO" "Deploying UI artifacts to Webapp service instance"
deploy_ui_artifact
