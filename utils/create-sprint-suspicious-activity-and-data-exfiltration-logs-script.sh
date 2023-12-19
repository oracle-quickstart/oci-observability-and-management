#!/bin/bash

# Picks the username sent as an argument to made the logs with or picks the current user
USER_NAME=${1:-$(whoami)}

# A sample of Ip Addresses from multiple locations to trigger the alarm
SAMPLE_IP_ADDRESSES=( "22.60.240.244" "196.220.230.205" "40.39.48.34" "217.128.212.236" "17.241.30.58" )

# Generates the logs file content made of 5 unsuccesful login attempts OCI audit logs
for IP_ADDRESS in ${SAMPLE_IP_ADDRESSES[@]};
do

  # Generates the json content of the log
  echo -n "
{
  \"data\": {
    \"availabilityDomain\": \"AD1\",
    \"compartmentId\": \"ocid1.tenancy.uniqueId\",
    \"compartmentName\": \"tanancy-uuid\",
    \"eventName\": \"InteractiveLogin\",
    \"identity\": {
      \"ipAddress\": \"$IP_ADDRESS\",
      \"principalId\": \"ocid1.user.oc1.uniqueId\",
      \"principalName\": \"$USER_NAME\",
      \"tenantId\": \"ocid1.tenancy.uniqueId\",
      \"userAgent\": \"Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:109.0) Gecko/20100101 Firefox/115.0\"
    },
    \"message\": \"InteractiveLogin failed\",
    \"response\": {
      \"payload\": {
      \"login_input\": \"tenant: tanancy-uuid, user: $USER_NAME\",
      \"login_result\": \"PASSWORD_INVALID\"
      },
      \"responseTime\": \"2023-11-13T10:25:30.589Z\",
      \"status\": \"400\"
    }
  },
  \"time\": \"$(date +"%Y-%m-%dT%H:%M:%S%:%z")\",
  \"type\": \"com.oraclecloud.IdentitySignOn.InteractiveLogin\"
}";
done;

# Substitutes any trailing character by a new line
echo;