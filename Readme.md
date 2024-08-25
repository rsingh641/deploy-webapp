# Project Overview

This project is designed for managing and deploying infrastructure and applications on Azure. It includes scripts and configurations for setting up Azure resources, deploying a NodeJS and Spring Boot applications,
and managing environment-specific settings.

## Features

- **Multi-Environment Support**: Configuration and management for multiple environments (Development, Testing, Production, Disaster Recovery).
- **Azure Resource Management**: Scripts for creating and managing Azure resources, including Application Gateway, Traffic Manager, and Key Vault.
- **Application Deployment**: Automated deployment of Node.js (UI) and Spring Boot (Backend) applications to Azure App Services and Azure Spring Apps Service.
- **Blue-Green Deployment**: The project employs a Blue-Green Deployment model to minimize downtime and reduce risk during application updates. This approach involves maintaining two identical production environments, referred to as "Blue" and "Green."
The Node.js UI is deployed in two slots on Azure Web App service, and the Java Spring Boot Webservice is deployed in two deployment instances using Azure Spring App service. Blue-Green deployment switching is supported.
- **Environment-Specific Configurations**: Management of environment-specific properties and secrets, with support for encrypted secrets using SOPS and reading and writing secrets to Azure Key Vault Service.
- **Scaling and High Availability**: Functions for scaling applications and ensuring high availability through Traffic Manager profiles and Azure scaling capabilities.
- **Logging and Error Handling**: Comprehensive logging and error handling mechanisms for better visibility and troubleshooting.
- **Traffic Management**: Integration with Azure Traffic Manager for load balancing and failover strategies.
- **Observability**: Integration with Azure Application Insights for monitoring application performance and diagnostics.
- **Disaster Recovery**: A robust Disaster Recovery (DR) strategy is in place, with a fully functional DR environment hosted in a separate Azure region. The setup includes mechanisms for manually triggering failover, along with regular testing procedures to ensure seamless failover capability in case of an emergency.

## Directory Structure

### `./.sops.yaml`
Configuration file for SOPS (Secrets OPerationS) which defines how secrets should be encrypted and decrypted.
It uses Azure keyvault keys to encrypt secrets stored in repository.

### `./config`
Configuration files for different environments and general settings.

- **`./config/common`**: Contains common configuration properties used across all environments.
  - `common.properties`: General properties common for all environments.
  - `traffic_manager.properties`: Configuration for Traffic Manager.

- **`./config/environments`**: Environment-specific configurations.
  - **`dev`**: Development environment settings.
    - `dev.properties`: Environment properties.
    - `dev.secrets.enc.yaml`: Encrypted secrets for development.
    - `dev.ui.properties`: UI-specific properties.
    - `dev.webservice.properties`: Webservice-specific properties.
  - **`dr`**: Disaster Recovery environment settings.
    - Similar structure to `dev`.
  - **`prod`**: Production environment settings.
    - Similar structure to `dev`.
  - **`test`**: Test environment settings.
    - Similar structure to `dev`.

- **`./config/template`**: Templates for creating new environment configurations.
  - **`environment/env_name`**: Template structure for a new environment with placeholder values.

### `./src`
Scripts and source code for managing infrastructure and deployments.

- **`./src/create_app_infra.sh`**: Script to create Azure application infrastructure.
- **`./src/create_new_env_configuration.sh`**: Script to create a new environment configuration.
- **`./src/deploy_app.sh`**: Script to deploy the application to Azure.

- **`./src/lib`**: Library code divided into functional areas.
  - **`./src/lib/azure`**: Functions for managing Azure resources.
    - **`app_gateway`**: Application Gateway-related functions.
    - **`app_insights`**: Application Insights-related functions.
    - **`az_lib`**: General Azure CLI library functions.
    - **`failover`**: Failover-related functions.
    - **`keyvault`**: Key Vault-related functions.
    - **`network`**: Network-related functions.
    - **`storage_acc`**: Storage Account-related functions.
    - **`traffic_manager`**: Traffic Manager-related functions.
  - **`./src/lib/helper`**: Utility functions used across the project.
  - **`./src/lib/initialize`**: Initialization functions for setting up the project.
  - **`./src/lib/logging`**: Logging functions for error handling and information.
  - **`./src/lib/ui`**: Functions related to UI application deployment and management.
    - **`ui_app_deploy`**: Deployment scripts for UI applications.
    - **`ui_infra_deploy`**: Infrastructure deployment scripts for UI applications.
    - **`ui_manage`**: Management scripts for UI applications.
  - **`./src/lib/webservice`**: Functions related to webservice application deployment and management.
    - **`webservice_app_deploy`**: Deployment scripts for webservice applications.
    - **`webservice_infra_deploy`**: Infrastructure deployment scripts for webservice applications.
    - **`webservice_manage`**: Management scripts for webservice applications.

- **`./src/setup_traffic_manager.sh`**: Script to set up Traffic Manager profiles.

## Getting Started

1. **Configuration Setup**
   - Update the configuration files in `./config` as needed for your environments.

2. **Infrastructure Creation**
   - Run `./src/create_app_infra.sh` to create the necessary Azure infrastructure.

3. **Environment Configuration**
   - Run `./src/create_new_env_configuration.sh` to set up new environment configurations.

4. **Application Deployment**
   - Run `./src/deploy_app.sh` to deploy your application.

5. **Traffic Manager Setup**
   - Run `./src/setup_traffic_manager.sh` to configure Traffic Manager profiles.

## Logging

Logs are managed by the `logging` module in `./src/lib/logging`. Ensuring proper configuration for logging output.
Logs are created at users home path "~/deploy_webapps/logs/deploy_YYYYMMDD_HHMMSS.log"
Each run creates a new log file.

## Error Handling

The script intrupts immediately after encountering an error and displays the error on STDOUT and write to log file.
Error line is of format "script_file line_no. failure message".
Ensure to check logs for any issues during script execution.

## Observability

Application performance and diagnostics are monitored through Azure Application Insights.

