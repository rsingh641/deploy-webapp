# This script creates the necessary Azure cloud infrastructure for application

set -e

# Initialise the local environment
source src/lib/initialize
source src/lib/azure/app_gateway

logger "INFO" "Configuring Application Gateway for Webapp and Spring Webservice in ${ENV}"

logger "INFO" "Adding backend pool in Application Gateway for Webapp"
add_backend_pool "${WEBAPP_APP_GATEWAY_POOL_NAME}" "${WEBAPP_BACKEND_ADDRESSES}"

logger "INFO" "Adding backend pool in Application Gateway for Spring Webservice"
add_backend_pool "${SPRINGAPP_APP_GATEWAY_POOL_NAME}" "${SPRINGAPP_BACKEND_ADDRESSES}"

logger "INFO" "Adding HTTP setting in Application Gateway for Webapp"
create_http_settings "${WEBAPP_HTTP_SETTING_NAME}" ${WEBAPP_HTTP_SETTING_PORT} ${WEBAPP_HTTP_SETTING_PROTOCOL}

logger "INFO" "Adding HTTP setting in Application Gateway for Spring Webservice"
create_http_settings "${SPRINGAPP_HTTP_SETTING_NAME}" ${SPRINGAPP_HTTP_SETTING_PORT} ${SPRINGAPP_HTTP_SETTING_PROTOCOL}

logger "INFO" "Adding Routing rules in Application Gateway for Webapp"
create_routing_rule "${WEBAPP_ROUTING_RULE}" "${WEBAPP_LISTNER}" "${WEBAPP_APP_GATEWAY_POOL_NAME}" "${WEBAPP_HTTP_SETTING_NAME}"

logger "INFO" "Adding Routing rules in Application Gateway for Spring Webservice"
create_routing_rule "${SPRINGAPP_ROUTING_RULE}" "${SPRINGAPP_LISTNER}" "${SPRINGAPP_APP_GATEWAY_POOL_NAME}" "${SPRINGAPP_HTTP_SETTING_NAME}"

logger "INFO" "Successfully configured Application Gateway for Webapp and Spring Webservice in ${DR}"
