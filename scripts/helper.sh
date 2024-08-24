#! /bin/bash

set -e

# Function to handle errors and print line number
handle_error() {
    echo "Error on line $1"
    exit 1
}
trap 'handle_error $LINENO' ERR

# Function to handle logging
logger() {
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
fetch_secrets() {
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

replace_secrets() {
    BUILD="$LOCAL_ARTIFACT_DIR"
    FS=$'\37' # Using escape characters for sed delimiter

    sops -d $SECRETS_FILE | while read line
    do
        if [ ${line:0:1} == "#" ]; then
            continue
        fi
        key=$(echo $line | awk '{print $1}' | tr -d ':')
        value=$(echo $line | sed 's/\"/\\"/g' | awk '{$1="";print}' | xargs echo -n)
        # Below lines trims leading and trailing " in any property
        value="${value#\"}"
        value="${value%\"}"

        # Define application properties file here for
        find $SCRIPTS_ROOT_DIR -type f -name "*.*" -exec sed -i s${FS}"<${key}>"${FS}${value}${FS}g {} +

    done
}

replace_properties() {
    BUILD="$LOCAL_ARTIFACT_DIR"
    FS=$'\37' # Using escape characters for sed delimiter
    for line in $(cat  $PROPERTIES_FILE)
    do
        if [ ${line:0:1} == "#" ]; then
            continue
        fi
        IFS== read -r key value <<< "$line"
        if [ "$key" == "*URL" ]; then
            value=${value//['\']/'\\\'}
        fi

        # Define application properties file here for
        find $SCRIPTS_ROOT_DIR -type f -name "*.*" -exec sed -i s${FS}"<${key}>"${FS}${value}${FS}g {} +

    done
}


# Function to login to Azure
az_login() {
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

# Function to fetch secrets from Azure Key Vault and export key=value pairs as environment variables
load_secrets_from_keyvault() {
    local keyvault_name=$KEYVAULT_NAME

    if [ -z "$keyvault_name" ]; then
        echo "ERROR: Key Vault name is required"
        return 1
    fi

    echo "INFO: Fetching secrets from Key Vault: $keyvault_name"

    # List all secret names in the Key Vault
    secret_names=$(az keyvault secret list --vault-name "$keyvault_name" --query "[].name" -o tsv)

    if [ -z "$secret_names" ]; then
        echo "INFO: No secrets found in Key Vault: $keyvault_name"
        return 0
    fi

    # Iterate over each secret
    for secret_name in $secret_names; do
        # Fetch the secret value
        secret_value=$(az keyvault secret show --vault-name "$keyvault_name" --name "$secret_name" --query "value" -o tsv)

        if [ $? -ne 0 ]; then
            echo "ERROR: Failed to retrieve secret: $secret_name"
            return 1
        fi

        # Split the secret_value into individual key=value pairs and export each as an environment variable
        while IFS= read -r line; do
            # Ignore empty lines and lines starting with '#'
            if [[ -n "$line" && ! "$line" =~ ^# ]]; then
                key=$(echo "$line" | cut -d '=' -f 1)
                value=$(echo "$line" | cut -d '=' -f 2-)

                # Export the key=value as an environment variable
                export "$key=$value"
                echo "INFO: Loaded environment variable: $key"
            fi
        done <<< "$secret_value"
    done

    echo "INFO: All secrets have been loaded successfully"
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

# Function to store Oracle credentials in Key Vault as a secret
store_oracle_creds_in_key_vault() {
    logger "INFO" "Storing Oracle credentials in Key Vault as a secret..."

    # Prepare the secret value as key=value pairs separated by newlines
    oracle_secret_value="ORACLE_USERNAME=$ORACLE_USERNAME\nORACLE_PASSWORD=$ORACLE_PASSWORD"

    # Store the combined secret in Key Vault
    az keyvault secret set --vault-name "$KEYVAULT_NAME" --name "$ORACLE_SECRET_NAME" --value "$oracle_secret_value"
    
    if [ $? -ne 0 ]; then
        logger "ERROR" "Failed to store Oracle credentials in Key Vault $KEYVAULT_NAME"
        exit 1
    fi

    logger "INFO" "Oracle credentials successfully stored in Key Vault $KEYVAULT_NAME"
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
            az network vnet subnet create --resource-group "$RESOURCE_GROUP" --vnet-name "$VNET_NAME" \
            --address-prefixes "$subnet_prefix" --name "$subnet_name"
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

# Function to download artifact using wget
download_artifact() {
    # check if local artifactory path exists
    if [ ! -d "$LOCAL_ARTIFACT_DIR" ]; then
        mkdir -p "$LOCAL_ARTIFACT_DIR"
        if [ $? -ne 0 ]; then
            logger "ERROR" "Failed to create local artifact directory"
            exit 1
        fi
    fi

    local webservice_package="${ARTIFACT_URL}/${SPRING_APP_PACKAGE_NAME}"
    local ui_package="${ARTIFACT_URL}/${UI_PACKAGE_NAME}"

    if [ ! -f "$LOCAL_ARTIFACT_DIR/$SPRING_APP_PACKAGE_NAME" ]; then
        logger "INFO" "Downloading webservice package from URL: $webservice_package"
        
        wget -O "$LOCAL_ARTIFACT_DIR/$SPRING_APP_PACKAGE_NAME" $webservice_package

        if [ $? -ne 0 ]; then
            logger "ERROR" "Failed to download webservice artifact from URL"
            exit 1
        fi

        logger "INFO" "Webservice artifact downloaded successfully to $LOCAL_ARTIFACT_DIR/$SPRING_APP_PACKAGE_NAME"

    if [ ! -f "$LOCAL_ARTIFACT_DIR/$UI_PACKAGE_NAME" ]; then
        logger "INFO" "Downloading webservice package from URL: $ui_package"
        
        wget -O "$LOCAL_ARTIFACT_DIR/$UI_PACKAGE_NAME" $ui_package

        if [ $? -ne 0 ]; then
            logger "ERROR" "Failed to download ui artifact from URL"
            exit 1
        fi

        logger "INFO" "UI artifact downloaded successfully to $LOCAL_ARTIFACT_PATH"

    else
        logger "INFO" "UI artifact already downloaded: $LOCAL_ARTIFACT_DIR/$UI_PACKAGE_NAME"
    fi
}

# Function for scaling webservice
scale_spring_app() {
    logger "INFO" "Scaling Spring Boot Application..."
    local scale_command="az spring app scale --name $SPRING_APP_NAME --resource-group $SPRING_APP_RESOURCE_GROUP --service $SPRING_APP_SERVICE"

    # Append options if they are set
    [ -n "$SPRING_APP_CPU" ] && scale_command+=" --cpu $SPRING_APP_CPU"
    [ -n "$SPRING_APP_INSTANCE_COUNT" ] && scale_command+=" --instance-count $SPRING_APP_INSTANCE_COUNT"
    [ -n "$SPRING_APP_MAX_REPLICAS" ] && scale_command+=" --max-replicas $SPRING_APP_MAX_REPLICAS"
    [ -n "$SPRING_APP_MEMORY" ] && scale_command+=" --memory $SPRING_APP_MEMORY"
    [ -n "$SPRING_APP_MIN_REPLICAS" ] && scale_command+=" --min-replicas $SPRING_APP_MIN_REPLICAS"
    [ -n "$SPRING_APP_SCALE_RULE_NAME" ] && scale_command+=" --scale-rule-name $SPRING_APP_SCALE_RULE_NAME"
    [ -n "$SPRING_APP_SCALE_RULE_HTTP_CONCURRENCY" ] && scale_command+=" --scale-rule-http-concurrency $SPRING_APP_SCALE_RULE_HTTP_CONCURRENCY"
    [ -n "$SPRING_APP_SCALE_RULE_TYPE" ] && scale_command+=" --scale-rule-type $SPRING_APP_SCALE_RULE_TYPE"
    [ -n "$SPRING_APP_DEPLOYMENT_NAME" ] && scale_command+=" --deployment $SPRING_APP_DEPLOYMENT_NAME"

    # Execute the scale command and check for success
    if eval "$scale_command"; then
        echo "INFO: Successfully scaled Spring Boot app: $SPRING_APP_NAME"
    else
        echo "ERROR: Failed to scale Spring Boot app: $SPRING_APP_NAME" >&2
        exit 1
    fi
}

switch_webservice_deployment() {
    local deployment_name=$SPRING_APP_DEPLOYMENT_NAME
    local app_name=$SPRING_APP_NAME
    local resource_group=$RESOURCE_GROUP
    local service_name=$SPRING_APP_SERVICE

    # Build the command for setting the deployment
    local set_deployment_command="az spring app set-deployment --deployment $deployment_name --name $app_name --resource-group $resource_group --service $service_name"

    # Append --no-wait if the NO_WAIT flag is set
    [ "$SPRING_APP_NO_WAIT" = "true" ] && set_deployment_command+=" --no-wait"

    # Execute the command and check for success
    if eval "$set_deployment_command"; then
        echo "INFO: Successfully switched to deployment: $deployment_name for app: $app_name"
    else
        echo "ERROR: Failed to switch deployment to: $deployment_name for app: $app_name" >&2
        exit 1
    fi
}

start_webservice() {
    local app_name=$SPRING_APP_NAME
    local resource_group=$RESOURCE_GROUP
    local service_name=$SPRING_APP_SERVICE

    # Build the start command
    local start_command="az spring app start --name $app_name --resource-group $resource_group --service $service_name"

    # Append --deployment if specified
    [ -n "$SPRING_APP_DEPLOYMENT_NAME" ] && start_command+=" --deployment $SPRING_APP_DEPLOYMENT_NAME"

    # Append --no-wait if the NO_WAIT flag is set
    [ "$SPRING_APP_NO_WAIT" = "true" ] && start_command+=" --no-wait"

    # Execute the command and check for success
    if eval "$start_command"; then
        echo "INFO: Successfully started Spring Boot app: $app_name"
    else
        echo "ERROR: Failed to start Spring Boot app: $app_name" >&2
        exit 1
    fi
}

stop_webservice() {
    local app_name=$SPRING_APP_NAME
    local resource_group=$RESOURCE_GROUP
    local service_name=$SPRING_APP_SERVICE

    # Build the stop command
    local stop_command="az spring app stop --name $app_name --resource-group $resource_group --service $service_name"

    # Append --deployment if specified
    [ -n "$SPRING_APP_DEPLOYMENT_NAME" ] && stop_command+=" --deployment $SPRING_APP_DEPLOYMENT_NAME"

    # Append --no-wait if the NO_WAIT flag is set
    [ "$SPRING_APP_NO_WAIT" = "true" ] && stop_command+=" --no-wait"

    # Execute the command and check for success
    if eval "$stop_command"; then
        echo "INFO: Successfully stopped Spring Boot app: $app_name"
    else
        echo "ERROR: Failed to stop Spring Boot app: $app_name" >&2
        exit 1
    fi
}

unset_webservice_deployment() {
    local app_name=$SPRING_APP_NAME
    local resource_group=$RESOURCE_GROUP
    local service_name=$SPRING_APP_SERVICE

    # Build the unset-deployment command
    local unset_deployment_command="az spring app unset-deployment --name $app_name --resource-group $resource_group --service $service_name"

    # Append --no-wait if the NO_WAIT flag is set
    [ "$SPRING_APP_NO_WAIT" = "true" ] && unset_deployment_command+=" --no-wait"

    # Execute the command and check for success
    if eval "$unset_deployment_command"; then
        echo "INFO: Successfully unset the deployment for Spring Boot app: $app_name"
    else
        echo "ERROR: Failed to unset the deployment for Spring Boot app: $app_name" >&2
        exit 1
    fi
}

create_storage_account_and_store_in_keyvault() {
    local resource_group=$RESOURCE_GROUP
    local storage_account_name=$STORAGE_ACCOUNT
    local key_vault_name=$KEYVAULT_NAME

    # Check if the storage account already exists
    local account_not_exists=$(az storage account check-name --name $storage_account_name --query 'nameAvailable' --output tsv)

    if [ "$account_not_exists" == "false" ]; then
        echo "INFO: Storage account $storage_account_name already exists. Skipping creation."
        return 0
    fi

    # Create the storage account
    echo "INFO: Creating storage account: $storage_account_name"
    az storage account create --name $storage_account_name \
                             --resource-group $resource_group \
                             --location $LOCATION \
                             --sku Standard_LRS \
                             --kind StorageV2

    if [ $? -ne 0 ]; then
        echo "ERROR: Failed to create storage account: $storage_account_name" >&2
        exit 1
    fi

    echo "INFO: Storage account $storage_account_name created successfully."

    # Retrieve the storage account keys
    local keys=$(az storage account keys list --resource-group $resource_group \
                                              --account-name $storage_account_name \
                                              --query '[0].{key: value}' \
                                              --output tsv)

    if [ $? -ne 0 ]; then
        echo "ERROR: Failed to retrieve storage account keys for: $storage_account_name" >&2
        exit 1
    fi

    # Store the account name and key in Key Vault
    echo "INFO: Storing storage account credentials in Key Vault: $key_vault_name"
    az keyvault secret set --vault-name $key_vault_name \
                           --name "${storage_account_name}-account-name" \
                           --value $storage_account_name

    az keyvault secret set --vault-name $key_vault_name \
                           --name "${storage_account_name}-account-key" \
                           --value $keys

    if [ $? -ne 0 ]; then
        echo "ERROR: Failed to store storage account secrets in Key Vault" >&2
        exit 1
    fi

    echo "INFO: Storage account credentials stored in Key Vault successfully."
}

# Add Persistent storage account in spring app
add_storage_to_spring_app() {
    local resource_group=$RESOURCE_GROUP
    local spring_service_name=$SPRING_APP_SERVICE_NAME
    local spring_app_name=$SPRING_APP_tNAME
    local storage_account_name=$STORAGE_ACCOUNT
    local key_vault_name=$KEYVAULT_NAME

    # Fetch storage account name and key from Key Vault
    echo "INFO: Retrieving storage account credentials from Key Vault: $key_vault_name"

    local account_key=$(az keyvault secret show --vault-name $key_vault_name \
                                               --name "${storage_account_name}-account-key" \
                                               --query value --output tsv)

    if [ -z "$storage_account_name" ] || [ -z "$account_key" ]; then
        echo "ERROR: Failed to retrieve storage account credentials from Key Vault" >&2
        exit 1
    fi

    # Add storage account to Spring App
    echo "INFO: Adding storage account $storage_account_name to Spring App $spring_app_name"
    az spring app storage add --resource-group $resource_group \
                              --service $spring_service_name \
                              --name $spring_app_name \
                              --storage-type StorageAccount \
                              --account-name $storage_account_name \
                              --account-key $account_key

    if [ $? -ne 0 ]; then
        echo "ERROR: Failed to add storage account $storage_account_name to Spring App $spring_app_name" >&2
        exit 1
    fi

    echo "INFO: Storage account $storage_account_name added to Spring App $spring_app_name successfully."
}


