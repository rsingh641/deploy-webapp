#! /bin/bash

set -e

source src/lib/initialize
source src/lib/ui/ui_app_deploy

logger "INFO" "Downloading app version ${APP_VERSION} artifacts"
download_artifact

logger "INFO" "Updating app version ${APP_VERSION} artifacts to UI Webapp"
update_ui_artifacts "$LOCAL_ARTIFACT_DIR/$WEBAPP_PACKAGE_NAME"
