#! /bin/bash

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
check_create_key_vault() {
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


