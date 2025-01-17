import io
import json
import logging
import oci
import datetime

from fdk.context import InvokeContext
from fdk import response

def handler(ctx, data: io.BytesIO = None):

    apm_traces_client = get_traces_client()
    body = get_body(data=data)

    try:
        query_response = apm_traces_client.query(apm_domain_id=body["apm_domain_id"],
                                                query_details=oci.apm_traces.models.QueryDetails(query_text=body["query_text"]),
                                                time_span_started_greater_than_or_equal_to=datetime.datetime.strptime(body["time_span_started_greater_than_or_equal_to"], "%Y-%m-%dT%H:%M:%S.%fZ"),
                                                time_span_started_less_than=datetime.datetime.strptime(body["time_span_started_less_than"], "%Y-%m-%dT%H:%M:%S.%fZ"),
                                                limit=900)
    except (Exception, ValueError) as ex:
        if "opc-request-id" not in str(ex):
            logging.getLogger().info('Error querying data, possibly due to missing parameter in body: ' + str(ex))
            return
        
        logging.getLogger().info('Error querying data: ' + str(ex))
        return
    
    
    if is_timeseries_data(query_response.data):
        result = transform_time_series_data(query_response.data)
    else:
        result = transform_data(query_response.data)
    
    result = json.dumps(result, sort_keys=True, indent=2, separators=(',', ': '))
    
    print("Query results after transformation:")
    print(result)

    return response.Response(
        ctx, response_data=result,
        headers={"Content-Type": "application/json"}
    )


def get_body(data: io.BytesIO):
    try:
        body = json.loads(data.getvalue())
        if ("query_text" not in body) and ("query_name" in body):
            body.update({"query_text": "fetch query result " + body["query_name"]})
    except (Exception, ValueError) as ex:
        logging.getLogger().info('error parsing json payload: ' + str(ex))
    
    return body

def get_traces_client():
    # ### Use the below config to run locally using config file authentication
    # config = oci.config.from_file(profile_name="")
    # token_file = config['security_token_file']
    # token = None
    # with open(token_file, 'r') as f:
    #     token = f.read()

    # private_key = oci.signer.load_private_key_from_file(config['key_file'])
    # signer = oci.auth.signers.SecurityTokenSigner(token, private_key) 
    # apm_traces_client = oci.apm_traces.QueryClient({'region': config['region']}, signer=signer)

    signer = oci.auth.signers.get_resource_principals_signer()
    apm_traces_client = oci.apm_traces.QueryClient(config={}, signer=signer)

    return apm_traces_client


def is_timeseries_data(data):
    for column in data.query_result_metadata_summary.query_result_row_type_summaries:
        if column.expression == "timeseries":
            return True
    return False

### Transforms normal non-Timeseries data
# The basic output would be a key value representation of each trace, array columns will be simplified as well for ease of use (for the first dimension)
def transform_data(data):
    date_columns = []
    for column in data.query_result_metadata_summary.query_result_row_type_summaries:
        if column.unit == "EPOCH_TIME_MS":
            date_columns.append(column.display_name)
    
    result = []

    for row in data.query_result_rows:
        new_row = row.query_result_row_data

        for key in list(new_row.keys()):
            if hasattr(new_row[key], "__len__") and (not isinstance(new_row[key], str)):
                for i in range(len(new_row[key])):
                    new_row[key][i] = new_row[key][i]["queryResultRowData"]

        for column in date_columns:
            new_row[column] = datetime.datetime.fromtimestamp(new_row[column] / 1000.0, tz=datetime.timezone.utc).strftime('%Y-%m-%dT%H:%M:%SZ')
        
        result.append(new_row)
    
    return result

### Transforms Timeseries to an easier to use, simple to read format
def transform_time_series_data(data):
    grouped_by_columns = []
    for column in data.query_result_metadata_summary.query_results_grouped_by:
        grouped_by_columns.append(column.query_results_grouped_by_column)
    for column in data.query_result_metadata_summary.query_result_row_type_summaries:
        if column.expression in grouped_by_columns:
            grouped_by_columns.remove(column.expression)
            grouped_by_columns.append(column.display_name)
    
    result = []
    for row in data.query_result_rows:
        timeseries = row.query_result_row_data['timeseries']

        for ts_row in timeseries:
            new_row = ts_row['queryResultRowData']

            for key in list(new_row.keys()):
                if key.startswith("time_bucket("):
                    bucket_in_minute = int(key.split('(')[1].split(',')[0])
                    date = datetime.datetime.fromtimestamp(new_row[key]* bucket_in_minute * 60, tz=datetime.timezone.utc)
                    new_row.pop(key, None)
                    new_row.update({"date": date.strftime('%Y-%m-%dT%H:%M:%SZ')})

            for name in grouped_by_columns:
                new_row.update({name: row.query_result_row_data[name]})
            
            result.append(new_row)
    
    return result

### Invoke this function using the code bellow, this should be the request body when ivoking the function
# b = io.BytesIO(str.encode(json.dumps(
#     {
#         "apm_domain_id": "ocid1.apmdomain.oc1.iad.xxxxxxxxxxxxxxxxxxx",
#         # "query_text": "", # You can use the query text to use the full query or just the query name, when both are set, the query text will be used
#         # "query_name": "test-sentSpan",
#         "time_span_started_greater_than_or_equal_to": "2015-09-04T06:18:46.305Z",
#         "time_span_started_less_than": "2033-08-18T22:58:41.091Z"
#     })))

# handler(ctx = InvokeContext("app_id", "app_name", "fn_id", "fn_name", "call_id"), data=b)
