import os
import random
from datetime import datetime, timedelta

ingested_time = datetime.utcnow() - timedelta(minutes=3)
time = ingested_time + timedelta(seconds=random.randint(1, 120))
formatted_ingested_time = ingested_time.strftime("%Y-%m-%dT%H:%M:%S.%f")[:-3] + "Z"
formatted_time = time.strftime("%Y-%m-%dT%H:%M:%S.%f")[:-3] + "Z"

log_string = f'''
{{
    "data": {{
        "apiType": "native",
        "authenticationType": "instance",
        "bucketCreator": "Unknown",
        "bucketId": "ocid1.bucket.oc1.abc.abcdef123456789",
        "bucketName": "log",
        "clientIpAddress": "192.168.0.104",
        "compartmentId": "ocid1.compartment.oc1..abcdefg1234568888",
        "compartmentName": "compartment_name",
        "credentials": "abcdef123456789abcdef",
        "eTag": "45385429-904b-4db1-866e-123",
        "endTime": "2020-09-29T20:02:31.811Z",
        "isPar": false,
        "message": "Object retrieved.",
        "namespaceName": "namespace_value",
        "objectName": "object_name",
        "opcRequestId": "iad-1:x-uGtXG5Wdk3abc",
        "principalId": "ocid1.instance.oc1.12345",
        "principalName": "UnknownPrincipal",
        "region": "us-region-2",
        "requestAction": "GET",
        "requestResourcePath": "/n/namespace_value/b/log/o/object_name",
        "startTime": "2023-09-29T20:02:31.787Z",
        "statusCode": 200,
        "tenantId": "ocid1.tenancy.oc1..6w4ohcbz7otxxy6kd",
        "tenantName": "loganprod",
        "userAgent": "Oracle-JavaSDK/1.19.3 (Linux/4.14.35-1902.305.4.el7uek.x86_64; Java/1.8.0_251; Java HotSpot(TM) 64-Bit GraalVM EE 19.3.2/25.251-b08-jvmci-20.1-b02-dev)",
        "vcnId": "477016"
    }},
    "id": "20919d7c-2d6d-401a-9858-123",
    "oracle": {{
        "compartmentid": "ocid1.compartment.oc1..lxenat5opur",
        "ingestedtime": "{formatted_ingested_time}",
        "loggroupid": "ocid1.loggroup.oc1.gmsmd5c7qmebnsyx7dm",
        "logid": "ocid1.log.oc1.iz6lu3innhmdyb6aiamaaaaa",
        "tenantid": "ocid1.tenancy.oc1..1234"
    }},
    "source": "log",
    "specversion": "1.0",
    "subject": "subject value",
    "time": "{formatted_time}",
    "type": "com.oraclecloud.objectstorage.getobject"
}}
'''

file_name = 'oci-storage-bucket-logs.log'

if os.path.exists(file_name):
    os.remove(file_name)

with open(file_name, 'a') as f:
  f.write(log_string)
f.close()
