Content-Type: multipart/mixed; boundary=MIMEBOUNDARY
MIME-Version: 1.0

--MIMEBOUNDARY
Content-Transfer-Encoding: 7bit
Content-Type: text/cloud-config
Mime-Version: 1.0

#cloud-config

output: {all: '| tee -a /var/log/cloud-init-output.log'}

logcfg: |
  [formatters]
  format=%(levelname)s %(asctime)s::: %(message)s


--MIMEBOUNDARY
Content-Transfer-Encoding: 7bit
Content-Type: text/x-shellscript
Mime-Version: 1.0

#!/bin/bash

# Copyright (c) 2022, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

TMP_DIR=/tmp/cloud_init_tmp
mkdir $TMP_DIR

BASE_DIR="/opt/oracle"
CREDS_JSON_FILE=$TMP_DIR/upsertCreds.json

cleanup_before_exit(){
	# Delete temporarily create files
  rm -rf $TMP_DIR

  echo "Deleted temporary files"
}

trap cleanup_before_exit EXIT 

echo "Installing oci-cli"

yum -y install python36-oci-cli

echo "Installing Jdk8"
yum -y install jdk1.8.x86_64

# Install management agent instead of using OCA 
echo "Getting agent url"
agenturl=$(oci management-agent agent-image list --auth instance_principal --compartment-id ${tenancy_id} | grep object-url | grep Linux | grep rpm | cut -d \" -f 4)
# extract bucket and namespace from url
namespace=$(echo $agenturl | cut -d\/ -f 5)
bucketName=$(echo $agenturl | cut -d\/ -f 7)

# get rpm
echo "Getting mgmt agent rpm $namespace:$bucketName $agenturl"
oci os object get --auth instance_principal --namespace $namespace --bucket-name $bucketName --name Linux-x86_64/latest/oracle.mgmt_agent.rpm --file $TMP_DIR/mgmt_agent.rpm

echo "Creating install key"
installKeyId=$(oci management-agent install-key create --auth instance_principal --display-name MgmtAgentInstallKey --compartment-id ${compartment_ocid} | grep managementagentinstallkey |cut -d\" -f 4)

echo "Getting install key cotent $installKeyId"
oci management-agent install-key get-install-key-content --auth instance_principal --management-agent-install-key-id $installKeyId --file $TMP_DIR/input.rsp

echo "Service.plugin.logan.download=true" >> $TMP_DIR/input.rsp

cp $TMP_DIR/input.rsp /tmp/input.rsp

echo "Installing Agent RPM"
sudo rpm -ivh $TMP_DIR/mgmt_agent.rpm

echo "Setting up agent"
sudo /opt/oracle/mgmt_agent/agent_inst/bin/setup.sh opts=$TMP_DIR/input.rsp

# Get secret from vault
password=$(oci secrets secret-bundle get --auth instance_principal --raw-output --secret-id ${secret_ocid} --query "data.\"secret-bundle-content\".content" | base64 -d )

# Create upsertCreds.json for cred utility
cat > $CREDS_JSON_FILE <<EOF
{
"source": "lacollector.la_database_sql",
"name": "LCAgentDBCreds.${entity_name}",
"type": "DBCreds",
"description":"This is a DB credential used to connect to EBS DB",
"usage": "LOGANALYTICS",
"disabled": "false",
"properties":[
        {"name":"DBUserName","value":"CLEAR[${username}]"},
        {"name":"DBPassword","value":"CLEAR[$password]"},
        {"name":"DBRole","value":"NORMAL"}
 ]
}
EOF

# Add creds in agent wallet
sudo -u mgmt_agent bash -c "cat $CREDS_JSON_FILE | bash /opt/oracle/mgmt_agent/agent_inst/bin/credential_mgmt.sh -s logan -o upsertCredentials"

echo "Successfully added secrets to agent wallet"

# Add EBS DB logon property
echo "loganalytics.database_sql.dblogonversion=omc_oracle_db_instance:${entity_name}=8" >> /opt/oracle/mgmt_agent/agent_inst/config/emd.properties

echo "Fetching schedule file from object storage"
# fetch schedule file from object storage
oci os object get --auth instance_principal --bucket-name ${bucket_name} --name ${schedule_file} --file $TMP_DIR/schedule_file.csv
cp $TMP_DIR/schedule_file.csv /tmp/schedule_file.csv

# put schedule file in agent directory 
sudo mkdir -p  $BASE_DIR/mgmt_agent/agent_inst/laconfig && sudo cp $TMP_DIR/schedule_file.csv $BASE_DIR/mgmt_agent/agent_inst/laconfig/logan_schedule_database_sql_ebs.csv

echo "Restarting mgmt agent"
# restart agent
sudo systemctl stop mgmt_agent; sleep 5; sudo systemctl start mgmt_agent

--MIMEBOUNDARY--
