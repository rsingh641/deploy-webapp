#! /bin/bash

set -e

source src/lib/initialize
source src/lib/webservice/webservice_app_deploy


logger "INFO" "Downloading app version ${APP_VERSION} artifacts"
download_artifact

logger "INFO" "Updating app version ${APP_VERSION} artifacts to Spring Webservice"
update_webservice_artifacts "$LOCAL_ARTIFACT_DIR/$SPRING_APP_PACKAGE_NAME"

