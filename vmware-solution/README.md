# VMWare Solution Installation
## Compute Instance
For OCI SDDC, create a new compute instance (or use an existing one) in the same VCN where SDDC exists.  For On-Prem VMWare, use any linux VM that can access vCenter, OCI Services, and Internet (to install python modules).

## Syslog Collection Setup 
Management Agent is used to forward vCenter Syslog to Log analytics. It is not used in collecting/uploading metrics/events/alarms.

### Enable OCA Management agent
Deploy Log Analytics Plugin
Associate "VMWare vSphere Syslog  Logs" to host entity  
In the vCenter, configure Syslog to be sent to the host at port 8519.  If this port can not be used then user will have to edit the Source in LA and specify the port there. 

## VMWare Collector Setup
### Prerequisites
* The customer tenancy should be onboarded to Log Analytics in the region
* There should be a user who has the permission to create entities & log groups in Log Analytics and to upload logs
* Store vCenter user name and password in OCI Vault (base64 format)
* Create a Log Group  in Log analytics to store Logs
* Download solution zip file from github to the compute host created earlier
* The following information is needed:
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
* OCI Config File
    * Copy OCI private key and save in a file in ~/.oci directory of the user
    * Create config file with the following entries:
```
[DEFAULT]
fingerprint = <key fingerprint>
key_file =/home/opc/.oci/oci_api_key.pem
tenancy = <tenancy-id>
region = <region>
user = <user-ocid>
```
### Download and Configure Solution Zip File
* Download Solution Zip file from github
* Unzip it in the installation directory
* Copy config.yaml.sample to config.yaml and update it:
```
oci:
  log_analytics_namespace: <namespace>
  region: <region>  # e.g. us-phoenix-1
  compartment_id: <compartment_ocid>
  log_group_id: <log group ocid>
  config_file: <config file path>
  profile: DEFAULT
  metrics_source: VMWare vSphere Metrics 
  alarms_source: VMWare vSphere Alarms
  events_source: VMWare vSphere Events

vcenter:
  host: <vcenter host>
  user_secret_ocid: <user-secret-ocid>
  password_secret_ocid: <password-secret-ocid>
  port: 443
  batch_size: 1000   # 👈 new (default will be 1000 if omitted)

dry_run: false
```
### Install Python Modules 
Run `setup_python.sh` script to make sure correct version of python and required modules are installed.

### Discover and Initialize Entities
Edit bin/run.sh to update BASE_DIR value. Run "bin/run.sh init_entities" to discover entities in VMWare and create in Log Analytics. 

Verify that  VMWare vCenter, Data Center, Cluster, Host, VM etc. entities have been created in Log Analytics. 

### Test Data Collection
Run `bin/run.sh  metrics` to send metrics to Log Analytics. Check if the metric data can be searched in OCI Log Explorer.

### Create Crontab Entries
Run `crontab -e`  and add the following content:


```
*/5 * * * * /home/opc/logan_collectors/bin/run.sh metrics
*/5 * * * * /home/opc/logan_collectors/bin/run.sh alarms
*/5 * * * * /home/opc/logan_collectors/bin/run.sh events
0 * * * * /home/opc/logan_collectors/bin/run.sh sync_entities
```

## Appendix A: Setting up OCI User with Permissions
Create a user that will be used to access OCI services. Put the users in a group "Logan Uploader".  With the group following permissions:
```
"Allow group LoaganUploader to use virtual-network-family in compartment id <compartment_ocid>",
"Allow service loganalytics to inspect compartments in tenancy",
"Allow service loganalytics to read loganalytics-feature-family in tenancy",
"Allow group LoaganUploader to manage all-resources in compartment id <compartment_ocid>,
"Allow group LoaganUploader to use loganalytics-ondemand-upload in tenancy", 
"Allow group LoaganUploader to {LOG_ANALYTICS_LOG_GROUP_UPLOAD_LOGS, LOG_ANALYTICS_ENTITY_UPLOAD_LOGS, LOG_ANALYTICS_SOURCE_READ} in tenancy
"Allow group LoaganUploader to read secret-family in compartment id <compartment-ocid>"
```

## Appendix B: Setting up log rotation
Create a new file /etc/logrotate.d/vmwarelogan with the following content

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

