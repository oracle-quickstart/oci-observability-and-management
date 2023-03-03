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

BASE_DIR="/var/lib/oracle-cloud-agent/plugins/oci-managementagent"
CREDS_JSON_FILE=$TMP_DIR/upsertCreds.json
PLUGIN_OCID_FILE=$TMP_DIR/plugin.ocid
AGENT_OCID_FILE=$TMP_DIR/agent.ocid
TIMEOUT_EXITCODE=2

cleanup_before_exit(){
	# Delete temporarily create files
  rm -rf $TMP_DIR

  echo "Deleted temporary files"
}

trap cleanup_before_exit EXIT 

startTime=10#$(date +"%M")
while true
do
    sleep 10s

    if [[ -d "$BASE_DIR/polaris/agent_inst/discovery/PrometheusEmitter" && ! -f "$BASE_DIR/polaris/agent_inst/config/security/resource/agent.lifecycle" ]]; then
        echo "Agent is available now"
        break
    else
        echo "Waiting for agent to become available..."
    fi

    diff=$((endTime - startTime))

    #Wait for max 5 mins
    if (( $diff >= 5 )); then
        echo "Timeout: $diff mins, timedout!"
        break
    fi
done


echo "Installing oci-cli"

yum -y install python36-oci-cli

# Read agent ocid file
source $BASE_DIR/polaris/agent_inst/config/security/resource/agent.ocid

# Create agent.ocid file for CLI
cat > $AGENT_OCID_FILE <<EOF
[
"$agent"
]
EOF

# Get plugin ocid and create plugin.ocid
echo "Getting plugin ocid"
oci --auth instance_principal management-agent plugin list --compartment-id ${compartment_ocid} --query "data[?name == 'logan'].id" > $PLUGIN_OCID_FILE

# Deploy logan plugin
echo "Deploying Logan plugin"
deployPlugin=$(oci --auth instance_principal management-agent agent deploy-plugins --agent-compartment-id "${compartment_ocid}" --agent-ids file://$AGENT_OCID_FILE --plugin-ids file://$PLUGIN_OCID_FILE --wait-for-state SUCCEEDED --max-wait-seconds 300 2>&1)
deployPluginExitCode=$?

if [[ $deployPluginExitCode != 0 ]]; then
  echo "Failed to deploy plugin due to: $deployPlugin"

  if [[ $deployPluginExitCode == $TIMEOUT_EXITCODE ]]; then
    echo "Manually checking if plugin deployment succeeded..."
    pluginFound=$(oci management-agent agent get --agent-id $agent --auth instance_principal --raw-output --query "data.\"plugin-list\"" | grep "logan" 2>&1)
    pluginFoundExitCode=$?

    if [[ $pluginFoundExitCode != 0 ]]; then
      echo "No Logan plugin found, exiting Management Agent setup"
      exit 1
    fi
  else
    echo "Exiting Management Agent setup"
    exit 1
  fi
fi

echo "Successfully deployed logan plugin"

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
sudo -u oracle-cloud-agent bash -c "cat $CREDS_JSON_FILE | bash $BASE_DIR/polaris/agent_inst/bin/credential_mgmt.sh -s logan -o upsertCredentials"

echo "Successfully added secrets to agent wallet"

# Add EBS DB logon property
echo "loganalytics.database_sql.dblogonversion=omc_oracle_db_instance:${entity_name}=8" >> $BASE_DIR/polaris/agent_inst/config/emd.properties

echo "Fetching schedule file from object storage"
# fetch schedule file from object storage
oci os object get --auth instance_principal --bucket-name ${bucket_name} --name ${schedule_file} --file $TMP_DIR/schedule_file.csv
cp $TMP_DIR/schedule_file.csv /tmp/schedule_file.csv

# put schedule file in agent directory 
sudo mkdir -p  $BASE_DIR/polaris/agent_inst/laconfig && sudo cp $TMP_DIR/schedule_file.csv $BASE_DIR/polaris/agent_inst/laconfig/logan_schedule_database_sql_ebs.csv

echo "Restarting mgmt agent"
# restart agent
sudo systemctl stop oracle-cloud-agent; sleep 5; sudo systemctl start oracle-cloud-agent

--MIMEBOUNDARY--
