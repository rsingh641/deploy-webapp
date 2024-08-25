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


# Project Features

### Multi-Environment Configuration
Supports configuration management across multiple environments (dev, test, prod, DR, Perf) with environment-specific properties and secrets, ensuring consistency and isolation of configurations.

### Encrypted Secrets Management
Utilizes SOPS for managing encrypted secrets, ensuring sensitive information is securely stored and accessible only with proper decryption.

## Automated Backup and Failover
Includes scripts for enabling automatic backups, performing manual backups, and managing failovers between production and disaster recovery environments to ensure data resilience and availability.

## Blue-Green Deployment Strategy
Implements blue-green deployment scripts to facilitate zero-downtime deployments and smooth transitions between application versions, minimizing service disruption.

## Infrastructure Automation
Automates the creation and configuration of infrastructure components, such as application gateways, network resources, and autoscaling, reducing manual setup and configuration efforts.

## Monitoring and Alerting
Features scripts to enable monitoring and alerting, ensuring timely detection of issues and proactive management of application performance and health.

## Scaling Management
Provides scripts for scaling applications both vertically and horizontally, including autoscaling capabilities to handle varying loads and maintain performance.

## UI and Web Service Management
Contains scripts for managing UI and web service operations, including starting, stopping, restarting, and updating services, simplifying maintenance and operational tasks.

## Template-Based Environment Creation
Offers templates for creating new environment configurations, allowing for quick setup of new environments with predefined settings and properties.

## Library of Azure Functions
Includes a comprehensive set of libraries for interacting with Azure services, such as app gateway, key vault, and traffic manager, streamlining Azure resource management.

## Detailed Logging and Initialization
Provides logging utilities and initialization scripts to ensure proper setup and monitoring of application and infrastructure components.

## Failover Mechanism Using Azure Traffic Manager
Features a failover mechanism leveraging Azure Traffic Manager to ensure high availability between Production and Disaster Recovery (DR) environments. Traffic Manager routes traffic based on configured policies and health checks, enabling seamless failover from Prod to DR in case of a failure. Includes scripts for configuring Traffic Manager profiles and managing traffic routing between environments to maintain service continuity and minimize downtime.


## Directory Structure

### Configuration

- **`./.sops.yaml`**
  - Configuration file for SOPS (Secrets OPerationS) which defines how secrets should be encrypted and decrypted.
    It uses Azure keyvault keys to encrypt secrets stored in repository.

- **`./config/`**
  - Contains configuration files for different environments and templates.

  - **`./config/common/`**
    - Contains properties and configuration shared across different environments.
    - **`common.properties`**
      - General properties applicable to all environments.
    - **`traffic_manager.properties`**
      - Configuration settings for managing traffic.

  - **`./config/environments/`**
    - Environment-specific configuration files.

    - **`./config/environments/dev/`**
      - Configuration for the development environment.
      - **`dev.properties`**
        - Properties specific to the development environment.
      - **`dev.secrets.enc.yaml`**
        - Encrypted secrets for the development environment.
      - **`dev.ui.properties`**
        - UI-specific properties for the development environment.
      - **`dev.webservice.properties`**
        - Web service-specific properties for the development environment.

    - **`./config/environments/dr/`**
      - Configuration for the dr environment.
      -  Same as dev.

    - **`./config/environments/prod/`**
      - Configuration for the production environment.
      -  Same as dev.

    - **`./config/environments/test/`**
      - Configuration for the testing environment.
      -  Same as dev.

  - **`./config/template/`**
    - Templates for creating new environments.
    - **`./config/template/environment/`**
      - **`env_name/`**
        - Placeholder for environment-specific configurations.
        - **`env.properties`**
          - Properties for a new environment.
        - **`env.secrets.enc.yaml`**
          - Encrypted secrets for a new environment.
        - **`env.ui.properties`**
          - UI-specific properties for a new environment.
        - **`env.webservice.properties`**
          - Web service-specific properties for a new environment.

### Source Code

- **`./src/`**
  - Contains scripts and libraries for various operational tasks.

  - **`./src/backup/`**
    - Scripts for managing backups.
    - **`enable_auto_backups.sh`**
      - Script to enable automatic backups for applications.
    - **`manual_backup_webapp.sh`**
      - Script to perform manual backups of the web application.

  - **`./src/blue-green-control/`**
    - Scripts for managing blue-green deployment strategy.
    - **`./src/blue-green-control/ui/`**
      - **`ui_switch_blue_to_green.sh`**
        - Switch the UI deployment from blue to green.
      - **`ui_switch_green_to_blue.sh`**
        - Switch the UI deployment from green to blue.
    - **`./src/blue-green-control/webservice/`**
      - **`webservice_switch_blue_to_green.sh`**
        - Switch the web service deployment from blue to green.
      - **`webservice_switch_green_to_blue.sh`**
        - Switch the web service deployment from green to blue.

  - **`./src/create_new_env_configuration.sh`**
    - Script to generate configuration files for a new environment.

  - **`./src/deploy/`**
    - Scripts for deploying applications.
    - **`deploy_app.sh`**
      - Script to deploy the application to the specified environment.

  - **`./src/DR_resources/`**
    - Scripts for disaster recovery setup.
    - **`setup_traffic_manager.sh`**
      - Script to configure the traffic manager for disaster recovery scenarios.

  - **`./src/failover/`**
    - Scripts for handling failovers.
    - **`failover_to_DR.sh`**
      - Script to failover to disaster recovery.
    - **`failover_to_Prod.sh`**
      - Script to failover to production.
    - **`test_failover_to_DR.sh`**
      - Script to test failover to disaster recovery.
    - **`test_failover_to_PROD.sh`**
      - Script to test failover to production.

  - **`./src/infra/`**
    - Scripts for setting up infrastructure.
    - **`configure_app_gateway.sh`**
      - Script to configure the application gateway.
    - **`create_app_infra.sh`**
      - Script to create the necessary infrastructure for the application.
    - **`setup_blue_green_model.sh`**
      - Script to set up the blue-green deployment model.
    - **`setup_network_resources.sh`**
      - Script to configure network resources.

  - **`./src/lib/`**
    - Libraries for various functionalities.
    - **`./src/lib/azure/`**
      - Libraries for interacting with Azure services.
      - **`app_gateway/`**
        - Azure application gateway management functions.
      - **`app_insights/`**
        - Azure application insights management functions.
      - **`autoscaling/`**
        - Azure autoscaling management functions.
      - **`az_lib/`**
        - General Azure library functions.
      - **`backup/`**
        - Azure backup management functions.
      - **`failover/`**
        - Azure failover management functions.
      - **`keyvault/`**
        - Azure Key Vault management functions.
      - **`network/`**
        - Azure network management functions.
      - **`storage_acc/`**
        - Azure storage account management functions.
      - **`traffic_manager/`**
        - Azure traffic manager management functions.
    - **`./src/lib/helper/`**
      - Helper functions and utilities.
    - **`./src/lib/initialize/`**
      - Initialization scripts and functions for setting up the environment.
    - **`./src/lib/logging/`**
      - Logging utilities and functions.
    - **`./src/lib/ui/`**
      - Libraries for UI deployment and management.
    - **`./src/lib/webservice/`**
      - Libraries for web service deployment and management.

  - **`./src/manage/`**
    - Management scripts for UI and web services.
    - **`./src/manage/ui/`**
      - **`ui_restart.sh`**
        - Restart UI service.
      - **`ui_start.sh`**
        - Start UI service.
      - **`ui_stop.sh`**
        - Stop UI service.
      - **`ui_update.sh`**
        - Update UI service.
    - **`./src/manage/webservice/`**
      - **`webservice_restart.sh`**
        - Restart web service.
      - **`webservice_start.sh`**
        - Start web service.
      - **`webservice_stop.sh`**
        - Stop web service.
      - **`webservice_update.sh`**
        - Update web service.

  - **`./src/monitor/`**
    - Monitoring and alerting scripts.
    - **`enable_alerts.sh`**
      - Script to enable alerts for monitoring.
    - **`enable_monitoring.sh`**
      - Script to enable monitoring for applications.

  - **`./src/scaling/`**
    - Scripts for scaling applications.
    - **`enable_autoscaling.sh`**
      - Script to enable autoscaling for applications.
    - **`ui_scale.sh`**
      - Script to scale UI service.
    - **`webservice_scale.sh`**
      - Script to scale web service.

  - **`./src/update/`**
    - Update scripts for applications.
    - **`update_ui.sh`**
      - Script to update the UI service.
    - **`update_webservice.sh`**
      - Script to update the web service.

## Getting Started

1. **Environment Configuration**
   - Run `./src/create_new_env_configuration.sh` to set up new environment configurations.

2. **Configuration Setup**
   - Update the configuration files in `./config` as needed for your environments.

3. **Infrastructure Creation**
   - Run `./src/create_app_infra.sh` to create the necessary Azure infrastructure.

4. **Application Deployment**
   - Run `./src/deploy_app.sh` to deploy your application. It also configures Application Gateway

5. **Traffic Manager Setup** [only for Production and Disaster Recovery]
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

