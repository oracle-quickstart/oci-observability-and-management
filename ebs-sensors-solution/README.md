# EBS-SENSORS
Oracle Logging Analytics can help you identify E Business Suite issues to make your business operations smooth to delight your customers. This resource manager stack configures logging analytics to enable these functional sensors such as:

General Ledger Period not closing (Receivables)
Incorrect payment to suppliers (Payables)
Invoice issues impacting cash flow (Projects)
Missing transactions impacting financial statement generation (Financial control)
Issues in EMEA VAT Reporting (Financials)
Unresolved depreciation issues causing period closing issues (Fixed Assets)
Can’t override rate for correct payments (HR)
Employees can’t update timecard (Payroll)
Issues processing payment transactions (Sales/Marketing)
And 100s of more issues
This OCI Resource Manager stack creates a instance in the subnet from which EBS Database is accessible, configures Management Agent and Logging Analytics to run regular Business checks. It installs four new dashboards covering different tiers of EBS deployment. Note: This stack doesn't start standard Logs collection and Logging Analytics EBS Discovery from the UI should be used to discover and enable logs collection.

As part of this deployment, a compute instance is created and Oracle Cloud Agent is configured to collect log data. Users can select the EBS products that they are using and EBS sensor sources for those products are created. EBS Database entity and source-entity associations are also created.  

## Prerequisites
- VCN and subnet from where database can be accessed.
- The subnet should have access to OCI Services (via a Service Gateway)
- Quota to create the following resources: 1 Compute instance,  1 dynamic group, 1 policy
- Store EBS DB password in OCI Vault in base encoded form. 
- Store schedule file in OCI Object Storage bucket. 

If you don't have the required permissions and quota, contact your tenancy administrator. See [Policy Reference](https://docs.cloud.oracle.com/en-us/iaas/Content/Identity/Reference/policyreference.htm), [Service Limits](https://docs.cloud.oracle.com/en-us/iaas/Content/General/Concepts/servicelimits.htm), [Compartment Quotas](https://docs.cloud.oracle.com/iaas/Content/General/Concepts/resourcequotas.htm).

## Deploy Using Oracle Resource Manager

1. Click [![Deploy to Oracle Cloud](https://oci-resourcemanager-plugin.plugins.oci.oraclecloud.com/latest/deploy-to-oracle-cloud.svg)]()

#    If you aren't already signed in, when prompted, enter the tenancy and user credentials.

2. Review and accept the terms and conditions.

3. Select the region where you want to deploy the stack.

4. Follow the on-screen prompts and instructions to create the stack.

5. After creating the stack, click **Terraform Actions**, and select **Plan**.

6. Wait for the job to be completed, and review the plan.

    To make any changes, return to the Stack Details page, click **Edit Stack**, and make the required changes. Then, run the **Plan** action again.

7. If no further changes are necessary, return to the Stack Details page, click **Terraform Actions**, and select **Apply**.

## Deploy Using the Terraform CLI

### Clone the Module
Now, you'll want a local copy of this repo. You can make that with the commands:

    git clone https://github.com/oracle-quickstart/oci-observability-and-management.git
    cd oci-observability-and-management/ebs-sensors-solution
    ls

### Prerequisites
First off, you'll need to do some pre-deploy setup for Docker and Fn Project inside your machine:

```
sudo su -
yum update
yum install yum-utils
yum-config-manager --enable *addons
yum install docker-engine
groupadd docker
service docker restart
usermod -a -G docker opc
chmod 666 /var/run/docker.sock
exit
curl -LSs https://raw.githubusercontent.com/fnproject/cli/master/install | sh
exit
```
  
### Set Up and Configure Terraform

1. Complete the prerequisites described [here](https://github.com/cloud-partners/oci-prerequisites).

2. Create a `terraform.tfvars` file, and specify the following variables:

```
# Authentication
tenancy_ocid="<tenancy_ocid>"
auth_type="user"
# Config  file is ~/.oci/config 
config_file_profile="DEFAULT"

# Region
region = "<oci_region>"

# Compartment
compartment_ocid = "<compartment_ocid>"

# EBS DB Info
subnet_ocid="<DB_NETWORK_SUBNET_OCID>"
db_compartment="<DB_COMPARTMENT_OCID>"
db_cred_compartment="<VAULT_COMPARTMENT_OCID>"

db_host="<DB_HOST>"
db_port=<DB_PORT>
db_service="<DB_SERVICE_NAME>"
db_username="<DB_USER_NAME>"
db_credentials="<VAULT_SECRET_OCID>"
db_user_role="NORMAL"

#Agent Compute Instance Info
instance_name="EBSAgentVM"
availability_domain="<AD>"
instance_shape="VM.Standard.E2.1"
user_ssh_secret="<SSH-KEY>"

# Set to false if you want to manually create dynamic group and policies
setup_policies=true

# Location of schedule file
bucket_name="<BUCKET_NAME>"
file_name="logan_schedule_database_sql_EBS.csv"

# Log Analytics Resources
resource_compartment="<RESOURCE_COMPARTMENT_OCID>"
create_log_group=false
log_group_ocid="<LOG_GROUP_OCID>"
la_entity_name = "<EBSDB entity name>"

# Selected products
#products="Oracle Advanced Benefits,Oracle Advanced Supply Chain Planning,Oracle Approvals Management,Oracle Assets,Oracle Cash Management,Oracle Cost Management,Oracle E-Business Suite Technology Stack,Oracle Financials for EMEA,Oracle General Ledger,Oracle HRMS (UK),Oracle Human Resources,Oracle Inventory Management,Oracle iProcurement,Oracle Materials Requirement Planning,Oracle Order Management,Oracle Payables,Oracle Payroll,Oracle Process Manufacturing Financials,Oracle Process Manufacturing Process Execution,Oracle Project Billing,Oracle Project Costing,Oracle Project Planning and Control,Oracle Public Sector Financials,Oracle Purchasing,Oracle Receivables,Oracle Shipping Execution,Oracle Time and Labor,Oracle Trading Community,Oracle Work in Process,Oracle Workflow"

products="Oracle Advanced Benefits,Oracle Workflow"

### Create the Resources
Run the following commands:

    terraform init
    terraform plan
    terraform apply


```
Outputs:


### Destroy the Deployment
When you no longer need the deployment, you can run this command to destroy the resources:

    terraform destroy

### Dynamic Groups and Policies (if adding manually)

1. Create a dynamic group instance dynamic group with matching rule:
- ANY {instance.compartment.id = '<db_compartment_ocid>'}
2. Create dynamic group mgmtagent dynamic group with matching rule:
- ALL {resource.type='managementagent', resource.compartment.id='<db_compartment_ocid>'}
3. Create a policy at tenancy level with the following statements:
- Allow DYNAMIC-GROUP <mgmtagent_dynamic_group_name> to {LOG_ANALYTICS_LOG_GROUP_UPLOAD_LOGS} in tenancy
- ALLOW DYNAMIC-GROUP <mgmtagent_dynamic_group_name> TO MANAGE management-agents IN COMPARTMENT ID <db_compartment_ocid>
- ALLOW DYNAMIC-GROUP <mgmtagent_dynamic_group_name> TO USE METRICS IN COMPARTMENT ID <db_compartment_ocid>
- ALLOW DYNAMIC-GROUP <instance_dynamic_group_name> TO MANAGE management-agents IN COMPARTMENT ID <db_compartment_ocid>
- ALLOW DYNAMIC-GROUP <instance_dynamic_group_name> TO MANAGE management-agent-install-keys IN COMPARTMENT ID <db_compartment_ocid>
- ALLOW DYNAMIC-GROUP <instance_dynamic_group_name> TO MANAGE OBJECTS IN COMPARTMENT ID <db_compartment_ocid>
- ALLOW DYNAMIC-GROUP <instance_dynamic_group_name> TO READ BUCKETS IN COMPARTMENT ID <db_compartment_ocid>
- ALLOW DYNAMIC-GROUP <instance_dynamic_group_name> TO READ secret-family in COMPARTMENT ID <vault_compartment_ocid>} where target.secret.id = '<db_secret_ocid>'

