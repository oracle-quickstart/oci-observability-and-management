#
# postauditlogs version 1.0.
#
# Copyright (c) 2022 Oracle, Inc.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#

import io
import json
import oci 
import requests
import logging
import time
import datetime
import sys 
import os
from fdk import response
import oci.object_storage
import base64
from io import StringIO
from io import BytesIO
from oci._vendor import urllib3

#get auth token for idcs
def get_oauth_token(idcsurl,apiuser,apipwd):
   try:
      #Get a bearer auth token
      auth_str = apiuser + ':' + apipwd
      auth_bytes = auth_str.encode('ascii')
      base64_bytes = base64.b64encode(auth_bytes)
      auth = base64_bytes.decode('ascii')
      tokenurl = idcsurl + '/oauth2/v1/token'
      headers = {'Content-Type': 'application/x-www-form-urlencoded;charset=UTF-8', "Authorization" : "Basic " + auth}
      r = requests.post(tokenurl, headers=headers, data='grant_type=client_credentials&scope=urn:opc:idm:__myscopes__')
      if r.status_code == 200:
         print("INFO - Response from IDCS token OK", flush=True)
      else:
         raise SystemExit("Failed to post to IDCS")
      r_json = {}
      try:
         r_json = json.loads(r.text)
      except ValueError as e:
         print(r.text, flush=True)
         raise
      return r_json['access_token']
   except Exception as e:
      print('ERROR: Could not get IDCS Auth token', flush=True)
      raise
   return bearer_token

# fetch idcs audit data
def get_idcs_audit_data(bearer_token,idcsurl,startIndex,count,date_start,date_end):
     try:
        auditurl= idcsurl + '/admin/v1/AuditEvents?startIndex=' + str(startIndex) + '&count=' + str(count) + '&filter=timestamp+ge+%22' + date_start + '%22+and+timestamp+le+%22' + date_end + '%22' 
        headers = {"Authorization" : "Bearer " + bearer_token}
        r2= requests.get(auditurl, headers=headers)
        if r2.status_code == 200:
           print("INFO - Response from audit api OK", flush=True)
        else:
           raise SystemExit("Failed to get response from audit api")
        r2_json = {}
     except Exception as e:
        print('ERROR: Could not access audit api', flush=True)
        raise
     return r2

def handler(ctx, data: io.BytesIO=None):
        logging.basicConfig(level=logging.DEBUG)
        logging.getLogger('oci').setLevel(logging.INFO)
        signer = oci.auth.signers.get_resource_principals_signer()
        try:
                cfg = ctx.Config()
                idcsurl = cfg["IDCS_URL"]
                apiuser = cfg["IDCS_CLIENTID"]
                secret_id = cfg["IDCS_CLIENT_VAULTSECRET"]
                sourceName = cfg["LOG_SOURCE"]
                logGroupID = cfg["LOG_GROUP_ID"]
                destRegion = cfg["REGION"]
                bucketName = cfg["TRACKER_BUCKET"]
                trackerObjectName = cfg["TRACKER_OBJECT_NAME"]
                entityID = cfg["ENTITY_ID"]

                startIndex = 1 
                count = 1000
        except Exception as e:
                print('Missing function parameters', flush=True)
                raise

        try :
            vault_client =  oci.secrets.SecretsClient(config={}, signer=signer)
        except Exception as ex: 
            print('Error creating vault client', flush=True)
            raise

        try :
            log_analytics_client = oci.log_analytics.LogAnalyticsClient(config={}, signer=signer)
        except Exception as ex: 
            print('Error creating log analytics client', flush=True)
            raise


        print("destination region="+destRegion)
        #configuring the log analytics client for another region
        log_analytics_client.base_client.set_region(destRegion)

        idcs_client_secret = read_secret_value(vault_client, secret_id)
        auth_str = apiuser + ':' + idcs_client_secret
        auth_bytes = auth_str.encode('ascii')
        base64_bytes = base64.b64encode(auth_bytes)
        auth = base64_bytes.decode('ascii')

        bearer_token=get_oauth_token(idcsurl,apiuser,idcs_client_secret)

        objstr_client = oci.object_storage.ObjectStorageClient(config={}, signer=signer)
        namespace = objstr_client.get_namespace().data

        uploadName="idcsauditlog-function"
        fileName="idcsauditlog-file.log"

        now = datetime.datetime.utcnow()

        date_start = now.replace(minute=int(now.minute / 5) * 5, second=0, microsecond=0) - datetime.timedelta(minutes=5)
        date_start = get_tracker_timestamp(objstr_client, bucketName, trackerObjectName, date_start)
        date_end = now.replace(minute=int(now.minute / 5) * 5, second=0, microsecond=0)
        #date_end = date_start + datetime.timedelta(minutes=5)

        date_start = date_start.strftime("%Y-%m-%dT%H:%M:%S.000Z")
        date_end = date_end.strftime("%Y-%m-%dT%H:%M:%S.000Z")

        while True:
          data=get_idcs_audit_data(bearer_token,idcsurl,startIndex,count,date_start,date_end)
          data=data.json()
          logdata=data['Resources']
          print (logdata, flush=True)
          if not logdata:
            print("Got no log data from IDCS")
            break
    
          body = json.dumps(logdata)

          bdata = io.BytesIO(bytes(body, 'utf-8'))

          message=upload_object(log_analytics_client,namespace,uploadName,sourceName,fileName,logGroupID,bdata,entityID)
          print("Success:" + fileName + " uploaded into log analytics of "+ destRegion, flush=True)
          print("for reference: ",message,flush=True)
          startIndex += 1000

        output=store_tracker_timestamp(objstr_client, bucketName, trackerObjectName, date_end) 
        print("ObjectStore: " + str(output), flush=True);

        return response.Response(
                ctx,
                response_data=json.dumps({"auditlog": "{0}".format(logdata)}),
                headers={"Content-Type": "application/json"}
                )

#upload object function to upload to log analytics
def upload_object(log_analytics_client,namespace,name_logobject,sourceName,file_name,log_groupID,body, entityIDStr):
    #print(type(body), flush=True)
    try:
        resp_2 = log_analytics_client.upload_log_file(
                       namespace_name=namespace,
                       upload_name=name_logobject,
                       log_source_name=sourceName,
                       filename=file_name,
                       opc_meta_loggrpid=log_groupID,
                       upload_log_file_body= body,
                       retry_strategy=oci.retry.DEFAULT_RETRY_STRATEGY,
                       entity_id=entityIDStr)

        message=str(resp_2.data)
        return {"content":message}

    #Error handling for upload log analytics
    except oci.exceptions.ServiceError as e:
         print("ServiceError(LogAnalytics): ",e, flush=True)
         raise e

    except ValueError as e:
        print("ValueError(LogAnalytics):",e,flush=True)
        raise e

    except (oci.exceptions.ClientError,oci.exceptions.ConnectTimeout,oci.exceptions.MaximumWaitTimeExceeded,oci.exceptions.MissingEndpointForNonRegionalServiceClientError,
        oci.exceptions.WaitUntilNotSupported) as e:
        print("ClientSideError(LogAnalytics):",e, flush=True)
        raise e

    except Exception as e:
        print("HTTP Request/Response Error(LogAnalytics): check Destination_region spell and access/dynamic group and its policies ",flush=True)
        print(e,flush=True)
        raise e


def store_tracker_timestamp(osclient, bucketName, objectName, dateTime):
    content = dateTime
    namespace = osclient.get_namespace().data
    output=""
    try:
        object = osclient.put_object(namespace, bucketName, objectName, json.dumps(content))
        output = "Success: Put object '" + objectName + "' in bucket '" + bucketName + "'"
    except Exception as e:
        output = "Failed: " + str(e.message)
    return { "state": output } 

def get_tracker_timestamp(osclient,bucketName, objectName, defaultTime):
    namespace = osclient.get_namespace().data
    try:
        object = osclient.get_object(namespace, bucketName,objectName,retry_strategy= oci.retry.DEFAULT_RETRY_STRATEGY)
        if object.status == 200:
          date_string = str(object.data.text).strip('"')
          print("Timestamp from ObjectStorage" + date_string, flush=True)
          date_object = datetime.datetime.strptime(date_string, "%Y-%m-%dT%H:%M:%S.000Z")
        elif object.status == 404:
          date_object = defaultTime
        else:
            raise SystemExit("Cannot retrieve the object" + str(objectName))
    except Exception as e:
        print("Error getting timestamp from ObjectStorage:", e, flush=True)
        date_object = defaultTime

    return date_object

def read_secret_value(secret_client, secret_id):
    response = secret_client.get_secret_bundle(secret_id)
    base64_Secret_content = response.data.secret_bundle_content.content
    base64_secret_bytes = base64_Secret_content.encode('ascii')
    base64_message_bytes = base64.b64decode(base64_secret_bytes)
    secret_content = base64_message_bytes.decode('ascii')
    return secret_content
