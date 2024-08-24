#! /bin/bash

# This script creates an new environment configuration for the provided environment name

set -e

source src/lib/helper

# Set environment variables
if [ -n "$1" ]; then
    ENV="$1"
elif [ -z "$ENV" ]; then
    logger "ERROR" "Environment name is required"
    exit 1
fi

ENVIRONMENTS_DIR="config/environments"
ENV_TEMPLATE_DIR="config/template/environment/env_name"

ENV_DIR="${ENVIRONMENTS_DIR}/${ENV}"

logger "INFO" "Checking if environment configuration exists"
if [ -d "${ENV_DIR}" ]; then
  logger "ERROR" "Environment config directory already exist: ${ENV_DIR}"
  exit 1
fi

cp -r "${ENV_TEMPLATE_DIR}" "${ENVIRONMENTS_DIR}/${ENV}"

if [ $? -ne 0 ]; then
  logger "ERROR" "Failed to create environment config directory: ${ENV_DIR}"
  exit 1
fi

logger "INFO" "Generating environment configuration files"

new_env_dir="${ENVIRONMENTS_DIR}/${ENV}"

mv "${new_env_dir}"/env.properties            "${new_env_dir}"/${ENV}.properties
mv "${new_env_dir}"/env.secrets.enc.yaml      "${new_env_dir}"/${ENV}.secrets.enc.yaml
mv "${new_env_dir}"/env.ui.properties         "${new_env_dir}"/${ENV}.ui.properties
mv "${new_env_dir}"/env.webservice.properties "${new_env_dir}"/${ENV}.webservice.properties

# Replace "<env>" with $ENV in all files
sed -i "s/<env>/$ENV/g" "${new_env_dir}"/${ENV}.properties
sed -i "s/<env>/$ENV/g" "${new_env_dir}"/${ENV}.secrets.enc.yaml
sed -i "s/<env>/$ENV/g" "${new_env_dir}"/${ENV}.ui.properties
sed -i "s/<env>/$ENV/g" "${new_env_dir}"/${ENV}.webservice.properties

logger "INFO" "Adding path regex and sample azure-kv in sops file"
logger "INFO" "Please create new sops key for ${ENV} environment in azure keyvault and update sops file"

cat << EOF >> "../.sops.yaml"
  - path_regex: .*/config/environments/${ENV}/.*.enc.yaml$
    azure-kv: https://spos-${ENV}.vault.azure.net/keys/sops-key/env_sops_key
EOF

logger "INFO" "Successfully created new environment [${ENV}] configuration"

