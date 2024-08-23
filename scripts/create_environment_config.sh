#! /bin/bash

# This script creates an environment configuration directory based on the provided environment name

# Set environment variables
ENV=$1

set -e

source helper.sh

ENV_DIR="../config/environments/${ENV}"
logger "INFO" "Checking if environment configuration exists"
if [ -d "${ENV_DIR}" ]; then
  logger "ERROR" "Environment config directory already exist: ${ENV_DIR}"
  exit 1
fi

mkdir -p "${ENV_DIR}"

if [ $? -ne 0 ]; then
  logger "ERROR" "Failed to create environment config directory: ${ENV_DIR}"
  exit 1
fi

logger "INFO" "Generating environment configuration files"

logger "INFO" "Creating file ${ENV}.properties"

cat << EOF > "${ENV_DIR}/${ENV}.properties"
# Environment configs
ENV="${ENV}"
LOCATION=""
RESOURCE_GROUP="rg-\${ENV}"
VNET="vnet-\${ENV}"
KEY_VAULT_NAME="kv-\${ENV}"

#------------------------------
# Webapp configs

SPRING_APPS_SERVICE="spring-apps-\${ENV}"
APP_SERVICE_PLAN="app_service_\${ENV}"
SKU="B1"
WEBAPP_NAME="webservice_\${ENV}"
JAVA_VERSION=""
JAVA_RUNTIME=""
NODE_VERSION="14.0"

#----------------------------------
# Artifact configs

ARTIFACT_FEED_NAME="ArtifactFeed_\${ENV}"
ARTIFACT_PACKAGE_NAME="AppPackage_\${ENV}"
ARTIFACT_VERSION="1.0.0"
ARTIFACT_URL="https://pkgs.\${ENV}.azure.com/\${ORG_NAME}/\${PROJECT_NAME}/_artifacts/feed/\${ARTIFACT_FEED_NAME}"
EOF

# check if file is created and it has data
if [ ! -s "${ENV_DIR}/${ENV}.properties" ]; then
  logger "ERROR" "Failed to create ${ENV}.properties file"
  exit 1
fi

logger "INFO" "Creating file ${ENV}.secrets.enc.yaml"

cat << EOF > "${ENV_DIR}/${ENV}.secrets.enc.yaml"
KEYVAULT_NAME: kv-${ENV}
TENANT_ID: 
APP_HOSTNAME: "${ENV}.webapp"
DEPLOYMENT_USER: "${ENV}_deployment_user"
DEPLOYMENT_PASSWORD: "${ENV}_deployment_password"

DB2_DRIVER_CLASS_NAME: "com.ibm.db2.jcc.DB2Driver"
DB2_HOSTNAME: "10.0.0.1"
DB2_PORT: 50000
DB2_DEFAULT_DB_NAME: "SAMPLE"

ORACLE_DRIVER_CLASS_NAME: "oracle.jdbc.OracleDriver"
ORACLE_HOSTNAME: "10.0.1.1"
ORACLE_PORT: 1521
ORACLE_SERVICE_NAME: "orclpdb1"
ORACLE_USERNAME: "admin"
ORACLE_PASSWORD: "Password"
EOF

# check if file is created and it has data
if [ ! -s "${ENV_DIR}/${ENV}.secrets.enc.yaml" ]; then
  logger "ERROR" "Failed to create ${ENV}.secrets.enc.yaml file"
  exit 1
fi

logger "INFO" "Adding path regex and sample azure-kv in sops file"

cat << EOF >> "../.sops.yaml"
  - path_regex: .*/environments/${ENV}/.*.enc.yaml$
    azure-kv: https://spos-${ENV}.vault.azure.net/keys/sops-key/env_sops_key
EOF

