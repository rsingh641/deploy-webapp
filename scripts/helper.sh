#! /bin/bash

set -e

# Function to handle errors and print line number
handle_error() {
    echo "Error on line $1"
    exit 1
}
trap 'handle_error $LINENO' ERR

# Function to handle logging
logger(){
    LEVEL=$1
    MESSAGE=$2
    DATE_STRING=$(date)
    TO_SHOW="false"
    # LEVELS are INFO, DEBUG, ERROR
    if [ "$LEVEL" == "INFO" ]; then COLOR=$GREEN && TO_SHOW="true"
    elif ([ "$LEVEL" == "DEBUG" ] && [ "$DEBUG_ENABLED" == "true" ]); then COLOR=$BLUE && TO_SHOW="true" && MESSAGE="($DATE_STRING) $MESSAGE"
    elif [ "$LEVEL" == "ERROR" ]; then COLOR=$RED && TO_SHOW="true"
    fi
    if [ "$TO_SHOW" == "true" ]; then echo -e "${COLOR}$LEVEL: $MESSAGE${NC}"; fi
}

# Function to fetch secrets from the encrypted file
fetch_secrets(){
    SECRETS_FILE=$1
    FS=$'\37'
    sops -d $SECRETS_FILE | while read line
    do
        if [ ${line:0:1} == "#" ]; then
            continue
        fi
        key=$(echo $line | awk '{print $1}' | tr -d ':')
        value=$(echo $line | sed 's/\"/\\"/g' | awk '{$1="";print}' | xargs echo -n)
        # trim leading and trailing " in any property
        value="${value#\"}"
        value="${value%\"}"
        export ${key}=${value}
    done
}

# Function to login to Azure
az_login(){
    set -e
    # Check if the required environment variables are set
    # Jenkins or Gitlab Secret managers can be used to securely store the below parameters in vault
    # CLIENT_ID, CLIENT_SECRET, TENANT_ID, SUBSCRIPTION_ID can be loaded at runtime in runner's environment

    if [ -z "$CLIENT_ID" ]; then
        logger "ERROR" "Missing required environment variable: CLIENT_ID for Azure login."
        return 1
    fi
    if [ -z "$CLIENT_SECRET" ]; then
        logger "ERROR" "Missing required environment variable: CLIENT_SECRET for Azure login."
        return 1
    fi
    if [ -z "$TENANT_ID" ]; then
        logger "ERROR" "Missing required environment variable: TENANT_ID for Azure login."
        return 1
    fi
    if [ -z "$SUBSCRIPTION_ID" ]; then
        logger "ERROR" "Missing required environment variable: SUBSCRIPTION_ID for Azure login."
        return 1
    fi

    # Attempt to login using service principal
    if ! az login --service-principal -u $CLIENT_ID -p $CLIENT_SECRET --tenant $TENANT_ID 2>&1; then
        logger "ERROR" "Failed to login to Azure with service principal."
        return 1
    fi

    # Attempt to set the subscription
    if ! az account set --subscription $SUBSCRIPTION_ID 2>&1; then
        logger "ERROR" "Failed to set Azure subscription."
        return 1
    fi

    logger "INFO" "Successfully logged in and set the subscription."
    return 0
}

# Function to check and create Key Vault
check_and_create_key_vault() {
    logger "INFO" "Checking if Key Vault '$KEY_VAULT_NAME' exists..."

    if ! az keyvault show --name $KEY_VAULT_NAME > /dev/null 2>&1; then

        logger "INFO" "Key Vault '$KEY_VAULT_NAME' does not exist. Creating..."
        az keyvault create --name $KEY_VAULT_NAME --resource-group $RESOURCE_GROUP --location $LOCATION --sku standard
        if [ $? -ne 0 ]; then
            logger "ERROR" "Failed to create key vault $KEY_VAULT_NAME"
            exit 1
        fi
    else
        logger "DEBUG" "Key Vault '$KEY_VAULT_NAME' already exists."
    fi
}

# Function to upload DB2 certificate to Key Vault
upload_db2_cert_to_key_vault() {
    logger "INFO" "Uploading DB2 certificate to Key Vault..."
    az keyvault certificate import --vault-name $KEY_VAULT_NAME --name $DB2_CERT_NAME --file $DB2_CERT_PATH
    if [ $? -ne 0 ]; then
        logger "ERROR" "Failed to upload DB2 certificate to Key Vault"
        exit 1
    fi
}

# Function to store Oracle credentials in Key Vault
store_oracle_creds_in_key_vault() {
    logger "INFO" "Storing Oracle credentials in Key Vault..."
    az keyvault secret set --vault-name $KEY_VAULT_NAME --name $ORACLE_USERNAME_SECRET_NAME --value $ORACLE_USERNAME
    if [ $? -ne 0 ]; then
        logger "ERROR" "Failed to store Oracle username in Key Vault"
        exit 1
    fi

    az keyvault secret set --vault-name $KEY_VAULT_NAME --name $ORACLE_PASSWORD_SECRET_NAME --value $ORACLE_PASSWORD
    if [ $? -ne 0 ]; then
        logger "ERROR" "Failed to store Oracle password in Key Vault"
        exit 1
    fi
}

# Install Azure CLI
install_azure_cli() {
    logger "INFO" "Installing Azure CLI..."
    curl -sL https://aka.ms/InstallAzureCLI | bash
    if [ $? -ne 0 ]; then
        logger "ERROR" "Failed to install Azure CLI"
        exit 1
    fi
}

# Check and install Azure CLI
check_az_cli() {
    logger "INFO" "Checking if Azure CLI is installed..."
    if [ ! command -v az &> /dev/null ]; then
        install_azure_cli
    fi
    az version
    if [ $? -ne 0 ]; then
    logger "ERROR" "Failed to check Azure CLI version"
        exit 1
    fi
    logger "INFO" "Azure CLI is installed."

    # Enabling dynamic install of extensions without prompt
    az config set extension.use_dynamic_install=yes_without_prompt
}

# check and create app insights
check_and_create_app_insights() {
    # Check if the Application Insights instance exists
    echo "Checking if Application Insights instance '$APP_INSIGHTS_NAME' exists in resource group '$RESOURCE_GROUP'..."
    if az monitor app-insights component show --resource-group "$RESOURCE_GROUP" --app "$APP_INSIGHTS_NAME" > /dev/null 2>&1; then
        echo "Application Insights instance '$APP_INSIGHTS_NAME' already exists."
    else
        # Check if we need to create the Application Insights instance
        if [[ "$ENABLE_APP_INSIGHTS" == "true" ]]; then
            echo "Application Insights instance '$APP_INSIGHTS_NAME' does not exist. Creating it..."
            az monitor app-insights component create --app "$APP_INSIGHTS_NAME" --location "$LOCATION" --resource-group "$RESOURCE_GROUP" --kind web
            if [[ $? -eq 0 ]]; then
                echo "Application Insights instance '$APP_INSIGHTS_NAME' created successfully."
            else
                echo "Failed to create Application Insights instance '$APP_INSIGHTS_NAME'."
                exit 1
            fi
        else
            echo "Application Insights instance '$APP_INSIGHTS_NAME' does not exist and 'ENABLE_APP_INSIGHTS' flag is not set to true. Skipping creation."
        fi
    fi
}

# Check and create subnets
check_and_create_subnet() {
    local $subnet_name=$1
    local $subnet_prefix=$2

    # Check if the VNet exists
    # Check if the webservice subnet exists
    echo "Checking if subnet '$subnet_name' exists in VNet '$VNET_NAME'..."
    if az network vnet subnet show --resource-group "$RESOURCE_GROUP" --vnet-name "$VNET_NAME" --name "$subnet_name" > /dev/null 2>&1; then
        echo "Subnet '$subnet_name' already exists."
    else
        # Create the subnet if it is allowed
        if [[ "$ENABLE_SUBNET_CREATION" == "true" ]]; then
            echo "Subnet '$subnet_name' does not exist. Creating it..."
            az network vnet subnet create --resource-group "$RESOURCE_GROUP" --vnet-name "$VNET_NAME" --address-prefixes "$subnet_prefix" --name "$subnet_name"
            if [[ $? -eq 0 ]]; then
                echo "Subnet '$subnet_name' created successfully."
            else
                echo "Failed to create subnet '$subnet_name'."
                exit 1
            fi
        else
            echo "Subnet '$subnet_name' does not exist and 'ENABLE_SUBNET_CREATION' flag is not set to true. Skipping creation."
        fi
    fi
}
