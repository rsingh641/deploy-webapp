#! /bin/bash

set -e

source src/lib/initialize
source src/lib/azure/app_gateway

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

logger "INFO" "Configuring Application Gateway"
logger "INFO" "Adding backend pools in Application Gateway"
add_backend_pool "${WEBAPP_APP_GATEWAY_POOL_NAME}" "${WEBAPP_BACKEND_ADDRESSES}"
add_backend_pool "${SPRINGAPP_APP_GATEWAY_POOL_NAME}" "${SPRINGAPP_BACKEND_ADDRESSES}"

logger "INFO" "Adding HTTP setting in Application Gateway"
create_http_settings "${WEBAPP_HTTP_SETTING_NAME}" ${WEBAPP_HTTP_SETTING_PORT} ${WEBAPP_HTTP_SETTING_PROTOCOL}
create_http_settings "${SPRINGAPP_HTTP_SETTING_NAME}" ${SPRINGAPP_HTTP_SETTING_PORT} ${SPRINGAPP_HTTP_SETTING_PROTOCOL}

logger "INFO" "Adding Routing rules in Application Gateway"
create_routing_rule "${WEBAPP_ROUTING_RULE}" "${WEBAPP_LISTNER}" "${WEBAPP_APP_GATEWAY_POOL_NAME}" "${WEBAPP_HTTP_SETTING_NAME}"
create_routing_rule "${SPRINGAPP_ROUTING_RULE}" "${SPRINGAPP_LISTNER}" "${SPRINGAPP_APP_GATEWAY_POOL_NAME}" "${SPRINGAPP_HTTP_SETTING_NAME}"
