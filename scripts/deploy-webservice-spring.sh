#! /bin/bash

# Set error handling to exit the script immediately if a command fails
set -e

logger "INFO" "Deploying Webservice for [$ENV]"

# Check if Azure Spring Apps service exists
if ! az spring show --name $SPRING_APPS_SERVICE --resource-group $RESOURCE_GROUP &>/dev/null; then
    logger "INFO" "Creating Azure Spring Apps service: $SPRING_APPS_SERVICE"

    create_spring_inst="az spring create --name $SPRING_APPS_SERVICE --resource-group $RESOURCE_GROUP --location $LOCATION  \
                        --sku ${WEBSERVICE_SKU} --zone-redundant ${WEBSERVICE_ZONE_REDUNDANT} --vnet ${VNET_NAME} \
                        --app-network-resource-group ${RESOURCE_GROUP} --infra-resource-group ${WEBSERVICE_INFRA_RESOURCE_GROUP} \
                        --app-subnet ${WEBSERVICE_SUBNET_NAME} --service-runtime-subnet ${WEBSERVICE_RUNTIME_SUBNET_NAME}"

    if [[ $ENABLE_APP_INSIGHTS == "true" ]]; then
        create_spring_inst="$create_spring_inst --app-insights $APP_INSIGHT_NAME --sampling-rate $APP_INSIGHT_SAMPLING_RATE"
    else
        create_spring_inst="$create_spring_inst --disable-app-insights true"
    fi

    eval "$create_spring_inst"

    if [ $? -ne 0 ]; then
        logger "ERROR" "Failed to create Azure Spring Apps service"
        exit 1
    fi

    logger "INFO" "Azure Spring Apps service created successfully: $SPRING_APPS_SERVICE"

else
    logger "DEBUG" "Azure Spring Apps service $SPRING_APPS_SERVICE already exists"
fi

# Check if the Spring Boot app exists
if ! az spring app show --name $SPRING_APP_NAME --service $SPRING_APPS_SERVICE --resource-group $RESOURCE_GROUP &>/dev/null; then
    logger "INFO" "Creating Spring Boot app: $SPRING_APP_NAME"
    create_spring_app="az spring app create --name $SPRING_APP_NAME --service $SPRING_APPS_SERVICE --resource-group $RESOURCE_GROUP \
                        --runtime-version $JAVA_VERSION --assign-endpoint  true --assign-public-endpoint $SPRING_APP_PUBLIC_ENDPOINT \
                        --cpu $SPRING_APP_CPU --memory $SPRING_APP_MEMORY --instance-count $SPRING_APP_INSTANCE_COUNT \
                        --deployment-name $SPRING_APP_DEPLOYMENT_NAME --disable-probe $SPRING_APP_DISABLE_PROBE \
                        --enable-liveness-probe $SPRING_APP_ENABLE_LIVNESS_PROBE --enable-readiness-probe $SPRING_APP_ENABLE_READINESS_PROBE \
                        --enable-startup-probe $SPRING_APP_ENABLE_STARTUP_PROBE --enable-persistent-storage true"

    eval "$create_spring_app"

    if [ $? -ne 0 ]; then
        logger "ERROR" "Failed to create Spring Boot app"
        exit 1
    fi
    logger "INFO" "Spring Boot app created successfully: $SPRING_APP_NAME"
else
    logger "DEBUG" "Spring Boot app $SPRING_APP_NAME already exists"
fi



# Create App Service Plan
logger "DEBUG" "Checking if App Service Plan '$APP_SERVICE_PLAN' exists..."
if ! az appservice plan show --name $APP_SERVICE_PLAN --resource-group $RESOURCE_GROUP > /dev/null 2>&1; then
    logger "INFO" "App Service Plan '$APP_SERVICE_PLAN' does not exist. Creating..."

    az appservice plan create --name $APP_SERVICE_PLAN --resource-group $RESOURCE_GROUP --sku $SKU

    if [ $? -ne 0 ]; then
        logger "ERROR" "Failed to create app service plan"
        exit 1
    fi
else
    logger "DEBUG" "App Service Plan '$APP_SERVICE_PLAN' already exists."
fi

# Create Web App
logger "DEBUG" "Checking if Web App '$WEBAPP_NAME' exists..."
if ! az webapp show --name $WEBAPP_NAME --resource-group $RESOURCE_GROUP > /dev/null 2>&1; then
    logger "INFO" "Web App '$WEBAPP_NAME' does not exist. Creating..."

    az webapp create --resource-group $RESOURCE_GROUP --plan $APP_SERVICE_PLAN --name $WEBAPP_NAME --runtime "JAVA|$JAVA_VERSION-java$JAVA_VERSION" --deployment-local-git

    if [ $? -ne 0 ]; then
        logger "ERROR" "Failed to create web app"
        exit 1
    fi
else
    logger "DEBUG" "Web App '$WEBAPP_NAME' already exists."

fi

# Configure Java Version
logger "INFO" "Configuring Java Version..."
az webapp config set --resource-group $RESOURCE_GROUP --name $WEBAPP_NAME --java-version $JAVA_VERSION
if [ $? -ne 0 ]; then
  logger "ERROR" "Failed to configure Java version"
  exit 1
fi

# Download the artifact from Azure Artifacts
logger "INFO" "Downloading artifact from Azure Artifacts..."
curl -u $DEPLOYMENT_USER:$DEPLOYMENT_PASSWORD \
     -L "$ARTIFACT_URL/$ARTIFACT_PACKAGE_NAME/$ARTIFACT_VERSION/$ARTIFACT_PACKAGE_NAME-$ARTIFACT_VERSION.jar" \
     -o myapp.jar
if [ $? -ne 0 ]; then
    logger "ERROR" "Failed to download artifact from Azure Artifacts"
    exit 1
fi

# Create a temporary deployment package (ZIP file)
logger "INFO" "Creating deployment package..."
TEMP_DEPLOYMENT_DIR="${ENV}_deployment_package"
mkdir -p ${TEMP_DEPLOYMENT_DIR}
cp myapp.jar ${TEMP_DEPLOYMENT_DIR}/
cd ${TEMP_DEPLOYMENT_DIR}
zip -r myapp.zip myapp.jar
cd ..
if [ $? -ne 0 ]; then
    logger "ERROR" "Failed to create deployment package"
    exit 1
fi

# Deploy to Azure App Service
logger "INFO" "Deploying to Azure App Service..."
az webapp deployment source config-zip --resource-group $RESOURCE_GROUP --name $WEBAPP_NAME --src ${TEMP_DEPLOYMENT_DIR}/myapp.zip
if [ $? -ne 0 ]; then
    logger "ERROR" "Failed to deploy application to Azure App Service"
    exit 1
fi

logger "INFO" "Deployment successful!"

# Cleanup
rm -rf ${TEMP_DEPLOYMENT_DIR}
