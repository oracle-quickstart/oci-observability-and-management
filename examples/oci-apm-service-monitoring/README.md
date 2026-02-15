# OCI APM service monitoring using the APM Log Sender function

This project provides a Terraform-based setup for monitoring Oracle Cloud Infrastructure (OCI) services using Oracle Application Performance Monitoring (APM). It provisions all necessary OCI resources, including:

- Log and log group creation (unless a log is provided)
- OCI Functions application and function
- API Gateway
- Virtual Cloud Network (VCN) and networking components
- Service Connector Hub connection
- Required IAM policies

The solution uses the Log Sender PBF and the OCI Logging service to enable monitoring of your target service.

## Resources Created

When deployed, the following resources will be created (unless existing ones are provided):

- **1 x Log Group and Log** – to enable logging for the monitored service
- **1 x Virtual Cloud Network (VCN)** – named `apm-service-monitoring-vcn` with required networking
- **1 x OCI Application** – named `apm-service-monitoring-app`
- **1 x OCI Function** – named `apm-service-monitoring-function`
- **1 x Service Connector** – named `service-monitoring-connector`
- **IAM Policies** – for the Function and Service Connector to operate properly

> **Note:** If `log_id` is provided, the log and log group will **not** be created, and the specified log will be used instead. Ensure the provided log exists in the correct compartment. (More details below.)

---

## How to Use the Script

This Terraform script uses input variables to determine whether to create a new log resource or use an existing one.

- If `log_id` is **specified**, the script will use the existing log and **skip creating** a new log and log group.
- If `log_id` is **not specified**, then the following variables **must** be provided to create a new log:
  - `resource_id`: The OCID of the resource to monitor.
  - `log_service`: The service name. *(Default: Oracle Integration Cloud service)*
  - `log_category`: The log category. *(Default: Activity Stream)*

Ensure all required variables are provided based on your use case.

---

## Terraform Deployment

### Deploy to OCI with One Click

Click the button below to deploy the function directly to OCI using the Resource Manager. Some values will be prepopulated:

[![Deploy to Oracle Cloud](https://oci-resourcemanager-plugin.plugins.oci.oraclecloud.com/latest/deploy-to-oracle-cloud.svg)](https://cloud.oracle.com/resourcemanager/stacks/create?zipUrl=https://github.com/M-Iliass/oci-observability-and-management/releases/download/v1.0.1/oci-apm-service-monitoring.zip)

---

### Deploy Using Local Development Environment

#### 1. Prepare Your Variable File

Create a file named `terraform.tfvars` and populate it with the required values.

```hcl
tenancy_ocid      = "your-tenancy-ocid"
region            = "your-region"
apm_domain_id     = "your-apm-domain-id"
compartment_ocid  = "your-compartment-ocid"
resource_id       = "your-resource-id"
log_id            = "your-log-id"         # Optional
log_service       = "your-log-service"    # Required if log_id is not provided
log_category      = "your-log-category"   # Required if log_id is not provided
```

Refer to the How to Use the Script section to determine which variables are required in your scenario.


## Deploying the function:

Apply the changes using the following commands:

```
  terraform init
  terraform plan
  terraform apply
```
