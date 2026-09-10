# VMware Solution Installation Instructions

> **Current solution version:** 1.1.0 <!-- SOLUTION_VERSION -->

## Prerequisites
* Identify a compartment where Log Analytics resources can be located. [See Identify OCI Compartments to Place the Log Analytics Resources](https://docs.oracle.com/iaas/log-analytics/doc/enable-access-logging-analytics-its-resources.html#LOGAN-GUID-48E4BACA-99BE-4955-9C5D-D52DE739C102).

* Create an IAM policy with all the necessary permissions. Create a user in Oracle Cloud Infrastructure who can be granted access to services and OCI resources. Add the user to a user group. Provide permissions to that user group to be able to perform all the tasks related to this solution.
* Add policy statements to enable access to Oracle Log Analytics and its resources, and to grant access to user groups. [See Prerequisite IAM Policies](https://docs.oracle.com/en-us/iaas/log-analytics/doc/prerequisite-iam-policies.html).
* Add policy statements for permissions to deploy Management Agents and use the agent related resources. [See Allow Continuous Log Collection Using Management Agents](https://docs.oracle.com/en-us/iaas/log-analytics/doc/allow-continuous-log-collection-using-management-agents.html#GUID-AA23C2F5-6046-443C-A01B-A507E3B5BFB2).
* Additionally, add the following policy statements for permission to use VCN and secret resources:
```
Allow group <user_group_name> to use virtual-network-family in compartment id <compartment_ocid>
Allow group <user_group_name> to read secret-family in compartment id <compartment-ocid>
```
In the above statements, <compartment_ocid> is the OCID of the compartment where log group and other resources of Log Analytics are located.

* Access Oracle Log analytics and enable it for use. See [Enable Log Analytics](https://docs.oracle.com/iaas/log-analytics/doc/enable-access-logging-analytics-its-resources.html#LOGAN-GUID-EA2F6910-878F-483E-A36D-E880D7C2D5E3).
* Create a log group in Log Analytics to store logs. See [Create Log Groups to Store Your Logs](https://docs.oracle.com/iaas/log-analytics/doc/create-logging-analytics-resources.html#LOGAN-GUID-D1758CFB-861F-420D-B12F-34D1CC5E3E0E).
* Compute Instance: For Oracle Cloud Infrastructure based Software-Defined Data Center (SDDC), create or use an existing compute instance in the same VCN as the SDDC. In case of VMware on-premises, use a Linux VM that can access vCenter, OCI Services, and Internet (to install python modules).
* Store vCenter user name and password in OCI Vault (base64 format)
* Note the following information: 
    * User API Key 
    * API Key Fingerprint 
    * User OCID 
    * Tenancy OCID
    * vCenter Host 
    * vCenter User Secret OCID
    * vCenter Password Secret OCID
    * Region 
    * Namespace 
    * Log Group OCID
    * Compartment OCID
## Create OCI Configuration File
Copy the OCI private key and save in the oci_api_key.pem file in ~/.oci directory of the user. Create the configuration file with the following entries:
```
[DEFAULT]
fingerprint = <key_fingerprint>
key_file =/home/opc/.oci/oci_api_key.pem
tenancy = <tenancy_id>
region = <region>
user = <user_ocid>
```

## Download Solution Zip and Update Solution Configuration File
Download solution zip file logan_collectors.zip from github to the compute host created earlier. Unzip in a directory where you want to install. 

Copy config.yaml.sample to config.yaml file and update it:
```
oci:
  log_analytics_namespace: <namespace>
  region: <region>  # e.g. us-phoenix-1
  compartment_id: <compartment_ocid>
  log_group_id: <loggroup_ocid>
  config_file: <config_file_path>
  profile: DEFAULT
  metrics_source: VMWare vSphere Metrics 
  alarms_source: VMWare vSphere Alarms
  events_source: VMWare vSphere Events

vcenter:
  host: <vcenter_host>
  user_secret_ocid: <user_secret_ocid>
  password_secret_ocid: <password_secret_ocid>
  port: 443
  batch_size: 1000   # 👈 new (default will be 1000 if omitted)
```
In the above file:
* config_file_path: Full path of the OCI configuration file you created earlier.
* vcenter_host: The host name of the vcenter host

## Install Plugins on Compute Instance for Log Collection
* Enable Management Agent plug-in on Oracle Cloud Agent in your compute instance. See [Deploy Management Agents on Compute Instances](https://docs.oracle.com/iaas/management-agents/doc/management-agents-oracle-cloud-agent.html).
* Deploy Log Analytics Plug-in on Management Agent. See [Deploy Service Plug-ins](https://docs.oracle.com/iaas/management-agents/doc/management-agents-administration-tasks.html#OCIAG-GUID-4D3F3DC5-4ACF-48C6-B624-F74700D0C73F). 


## Install Python Modules 
Run "setup_python.sh" script to ensure that the right version of python and required modules are installed.

## Discover and Initialize Entities
Run "bin/run.sh init_entities" to discover entities in VMware and create in Log Analytics. The launcher automatically uses the directory containing the extracted `logan_collectors` package. To use a different directory, set `BASE_DIR` when invoking it.

For production deployments, `CONFIG_FILE`, `LOG_DIR`, `STATE_DIR`, and `PYTHON_BIN` can also be set to keep configuration and runtime data outside the extracted bundle. For example:

```
BASE_DIR=/opt/oracle/logan_collectors \
/opt/oracle/logan_collectors/bin/run.sh metrics
```

## Optional Runtime Environment File

To keep the same `bin/run.sh` command for standalone use and existing cron entries, copy `logan_collectors/runtime.env.sample` to `logan_collectors/runtime.env` and set the site-specific paths. `run.sh` loads this file automatically when present. The file is excluded from solution ZIP archives so customer settings are not overwritten during an upgrade.

```
cd <BASE-DIR>/logan_collectors
cp runtime.env.sample runtime.env
chmod 600 runtime.env
```

The file can set `BASE_DIR`, `CONFIG_FILE`, `LOG_DIR`, `STATE_DIR`, and `PYTHON_BIN`. To use an environment file stored elsewhere, pass `ENV_FILE=/path/to/runtime.env` before `run.sh`.

## Upgrade the Solution

The release ZIP intentionally excludes `config.yaml`, `runtime.env`, `logs/`, `state/`, and `venv/`. Preserve these runtime files during an upgrade, especially `state/`, which contains the event checkpoint used to prevent duplicate event uploads.

Download the new `logan_collectors.zip` to the collector host and verify its version before changing the running installation:

   ```
   unzip /path_to_logan_collectors.zip -d /path_of_existing_install
   ```
  Note : Prior to release 1.1.0, if you have manually edited run.sh file then you need to copy those changed env properties to runtime.env for the upgrade.

## Test Data Collection
Run the following command on your compute instance to send metrics to Log Analytics:
`bin/run.sh  metrics`
Check if the metric data can be searched in the Log Explorer in Log Analytics.

## Syslog Collection Setup
Management Agent is used for forwarding vCenter Syslog to Log analytics. It is not used for collecting/uploading metrics/events/alarms. Associate Oracle-defined log source **VMWare vSphere Syslog Logs** to vCenter host entity. 

In the vCenter, configure Syslog to be sent to the host at port 8519.  If this port can not be used, then edit the source in Log Analytics and specify the port there.


## Create Crontab Entries
Run "crontab -e" on your compute instance and add the following content:
```
*/5 * * * * <BASE_DIR>/logan_collectors/bin/run.sh metrics

*/5 * * * * <BASE_DIR>/logan_collectors/bin/run.sh alarms

*/5 * * * * <BASE_DIR>/logan_collectors/bin/run.sh events

0 * * * * <BASE_DIR>/logan_collectors/bin/run.sh entity_sync
```
Replace BASE_DIR with installation directory path in above example.


## Optional: Set Up Log Rotation
You may want to set up log rotation for managing the storage size and log compression in your compute instance. Create a new file /etc/logrotate.d/vmwarelogan with the following content: 
```
<base-dir>/logs/*.log
<base-dir>/logs/*.out {
    size 20M
    rotate 5
    compress
    missingok
    notifempty
    copytruncate
}
```
