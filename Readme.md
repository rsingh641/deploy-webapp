# Project Overview

This project is designed for managing and deploying infrastructure and applications on Azure. It includes scripts and configurations for setting up Azure resources, deploying a NodeJS and Spring Boot applications,
and managing environment-specific settings.

## Features

**Multi-Environment Configuration**
- Supports configuration management across multiple environments (dev, test, prod, DR, Perf) with environment-specific properties and secrets, ensuring consistency and isolation of configurations.

**Encrypted Secrets Management**
- Utilizes SOPS for managing encrypted secrets, ensuring sensitive information is securely stored and accessible only with proper decryption.

**Infrastructure Automation**
- Automates the creation and configuration of infrastructure components, such as application gateways, network resources, and autoscaling, reducing manual setup and configuration efforts.

**Application Deployment**
- Automated deployment of Node.js (UI) and Spring Boot (Backend) applications to Azure App Services and Azure Spring Apps Service.

**Automated Backup and Failover**
- Includes scripts for enabling automatic backups, performing manual backups, and managing failovers between production and disaster recovery environments to ensure application resilience and availability.

**Blue-Green Deployment Strategy**
- The project employs a Blue-Green Deployment model to minimize downtime and reduce risk during application updates. This approach involves maintaining two identical production environments, referred to as "Blue" and "Green."
The Node.js UI is deployed in two slots on Azure Web App service, and the Java Spring Boot Webservice is deployed in two deployment instances using Azure Spring App service. Blue-Green deployment switching is supported.

**Monitoring and Alerting**
- Features scripts to enable monitoring and alerting, ensuring timely detection of issues and proactive management of application performance and health.

**Auto Scaling and High Availability**
- Provides scripts for scaling applications, including autoscaling capabilities to handle varying loads and maintain performance.

**UI and Web Service Management**
- Contains scripts for managing UI and web service operations, including starting, stopping, restarting, and updating services, simplifying maintenance and operational tasks.

**Template-Based Environment Creation**
- Offers templates for creating new environment configurations, allowing for quick setup of new environments with predefined settings and properties.

**Library of Azure Functions**
- Includes a comprehensive set of libraries for interacting with Azure services, such as app gateway, key vault, and traffic manager, streamlining Azure resource management.

**Detailed Logging and Initialization**
- Provides logging utilities and initialization scripts to ensure proper setup and monitoring of application and infrastructure components.

**High Availability Strategies Implemented**

  1. **Zone Redundancy Enabled for NodeJs Webapp and Spring Boot Webservice**
  2. **Metrics based Auto Scaling and Manual Scaling Enabled to deploy multiple instances**
  3. **Blue-Green deployment strategy implemented for zero-downtime application upgrades**
  4. **Multi-Region Deployment - Production and DR deployed in different regions**
  5. **Traffic Routing with Azure Front Door Enabled**
  6. **Health Probes and Automatic Failover Enabled**
  7. **Continuous Monitoring and Alerting Enabled for both UI and Backend instances**
  8. **Disaster Recovery (DR) with manual failover to DR Enabled**

**Azure Front Door**
  - **Global Load Balancing**: Routes traffic to the nearest and healthiest backend for low latency and high performance.
  - **Health Probes & Failover**: Continuously monitors backend health, automatically rerouting traffic to healthy endpoints in case of failures.
  - **Traffic Routing**: Supports various routing methods (priority, weighted, geographic) for flexible traffic management.

**Failover Mechanism Using Azure Traffic Manager for Disaster recovery**
- Features a failover mechanism leveraging Azure Traffic Manager to ensure high availability between Production and Disaster Recovery (DR) environments. Traffic Manager routes traffic based on configured policies and health checks, enabling seamless failover from Prod to DR in case of a failure. Includes scripts for configuring Traffic Manager profiles and managing traffic routing between environments to maintain service continuity and minimize downtime.

- A robust Disaster Recovery (DR) strategy is in place, with a fully functional DR environment hosted in a separate Azure region. The setup includes mechanisms for manually triggering failover, along with regular testing procedures to ensure 
seamless failover capability in case of an emergency.

### Logging

Logs are managed by the `logging` module in `./src/lib/logging`. Ensuring proper configuration for logging output.
Logs are created at users home path "`~/deploy_webapps/logs/deploy_YYYYMMDD_HHMMSS.log`"
Each run creates a new log file.

### Error Handling

The script intrupts immediately after encountering an error and displays the error on STDOUT and write to log file.
Error line is of format "script_file line_no. failure message".
Ensure to check logs for any issues during script execution.

### Observability

Azure Application Insights and Azure Log Workspace are used for Application performance and diagnostics monititoring.
  - Action group has been created to receive Email and SMS alearts of following type
    The threshold for alerts can be configured through properties

  **Metric based Alearts**
  1. Node js Webapp CPU usage > 80%
  2. Node js Webapp MEMORY usage > 80%
  3. Spring Webservice CPU usage > 80%
  4. Spring Webservice CPU usage > 80%

### Autoscaling and Manual Scaling

Autoscaling and Manual Scaling has been implemented for both UI and Webservice. It properties can be configured in ui and webservice properties file.
 Metrics based autoscaling is configured using "CpuPercentage" > 70%.
 The max and min count of instances for UI and Webservice are controlled by configuration parameters.

**Manual scaling can be done using** 
  1. `./src/scaling/ui_sacle.sh`
  2. `./src/scaling/webservice_scale.sh`


## Getting Started

1. **Environment Configuration**
   - Run `./src/create_new_env_configuration.sh <env>` to set up new environment configurations.

2. **Configuration Setup**
   - Update the configuration files in `./config/environments/<env>/` as needed for your environments.

3. **Infrastructure Creation**
   - Run `./src/infra/create_app_infra.sh` to create the necessary Azure infrastructure.

4. **Application Gateway Creation**
   - Run `./src/infra/configure_app_gateway.sh` to create the Application gateway.

5. **Network Resources Creation**
   - Run `./src/infra/setup_network_resources.sh` to create the necessary Network components in Azure infrastructure.

6. **Setup Blue-Green Deployment** [only for Production and Disaster Recovery]
   - Run `./src/infra/setup_blue_green_model.sh` to create the necessary instances for Blue-Green deployment strategy in Azure infrastructure.

   - Run `./src/blue-green-control/ui/ui_switch_blue_to_green.sh` to switch the UI deployment from blue to green.
   - Run `./src/blue-green-control/ui/ui_switch_green_to_blue.sh` to switch the UI deployment from green to blue.

   - Run `./src/blue-green-control/webservice/webservice_switch_blue_to_green.sh` to switch the Webservice deployment from blue to green.
   - Run `./src/blue-green-control/webservice/webservice_switch_green_to_blue.sh` to switch the Webservice deployment from green to blue.

7. **Application Deployment**
   - Run `./src/deploy/deploy_app.sh` to deploy your application. It also configures Application Gateway

8. **Updating or Upgrading application builds or configuration updates**
   - Run `./src/update/ui_update.sh` to push updates to UI instance.
   - Run `./src/update/webservice_update.sh` to push updates to Webservice instance.

9. **Enable Autoscaling**
   - Run `./src/scaling/enable_autoscaling.sh` to enable autoscaling for ui and webservice instances.

10. **Manual scaling**
    - Run `./src/scaling/ui_scale.sh` to manually scale ui instances.
    - Run `./src/scaling/webservice_scale.sh` to manually scale webservice instances.

11. **Enable Monitoring**
    - Run `./src/monitor/enable_monitoring.sh` to enable monitoring of UI and Webservce instances using Application Insights and Azure Log Analytics Workspace

12. **Enable Alerts**
    - Run `./src/monitor/enable_alearts.sh` to enable metrics based email and sms alearts for UI and Webservice instances.

13. **Managing Instances**
    - Run `./src/manage/ui/ui_restart.sh` to restart UI instance.
    - Run `./src/manage/ui/ui_start.sh` to start UI instance.
    - Run `./src/manage/ui/ui_stop.sh` to stop UI instance.

    - Run `./src/manage/webservice/webservice_restart.sh` to restart Webservice instance.
    - Run `./src/manage/webservice/webservice_start.sh` to start Webservice instance.
    - Run `./src/manage/webservice/webservice_stop.sh` to stop Webservice instance.

14. **Traffic Manager Setup** [only for Production and Disaster Recovery]
    - Run `./src/global_resources/setup_traffic_manager.sh` to configure Traffic Manager profiles.

15. **Front door Setup** [only for Production and Disaster Recovery]
    - Run `./src/global_resources/setup_frontdoor.sh` to configure Front door resource and configure it.

16. **Handling manual Failover** [only for Production and Disaster Recovery]
    - Run `./src/failover/failover_to_DR.sh` to trigger failover from Prod to DR.
    - Run `./src/failover/failover_to_Prod.sh` to trigger failover from DR to Prod.

    - Run `./src/failover/test_failover_to_DR.sh` to test the failover from Prod to DR.
    - Run `./src/failover/test_failover_to_Prod.sh` to test the failover from DR to Prod.

17. **Enable Backups** [only for Production and Disaster Recovery]
    - Run `./src/backup/enable_auto_backups.sh` to enable schedule backup of azure resources using Azure Backups.
    - Run `./src/backup/manual_backup_webapp.sh` to trigger a manual backup of webapp using Azure Backups.


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
      - Configuration settings for Azure traffic manager.
    - **`frontdoor.properties`**
      - Configuration settings for managing Azure frontdoor settings.

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

  - **`./src/global_resources/`**
    - Scripts for creating and managing global resources like front door and traffic manager.
    - **`setup_traffic_manager.sh`**
      - Script to configure the traffic manager for disaster recovery scenarios.
    - **`setup_frontdoor.sh`**
      - Script to configure the front door for global load balancing.

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
      - **`frontdoor/`**
        - Azure front door management functions.
      - **`keyvault/`**
        - Azure Key Vault management functions.
      - **`log_analytics/`**
        - Azure Log Analytics management functions.
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
    - **`./src/manage/webservice/`**
      - **`webservice_restart.sh`**
        - Restart web service.
      - **`webservice_start.sh`**
        - Start web service.
      - **`webservice_stop.sh`**
        - Stop web service.

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
      - **`ui_update.sh`**
        - Update UI service.
      - **`webservice_update.sh`**
        - Update web service.

