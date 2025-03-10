import os
import io
import json
import logging
import oci
import datetime

from fdk import response
from urllib.parse import urlparse
from urllib.parse import parse_qs
from urllib.parse import unquote

def handler(ctx, data: io.BytesIO = None):

    parsed_url = urlparse(ctx.RequestURL())
    query_params = parse_qs(parsed_url.query)

    time_span_started_greater_than_or_equal_to = 0
    time_span_started_less_than = 0

    # Extract paramters
    try:
        if "query_result_name" in query_params:
            query_name = query_params['query_result_name'][0]
            query_text = "fetch query result " + query_name
        elif "query_tql" in query_params:
            query_text = unquote(query_params['query_tql'][0])
            time_span_started_less_than = parseTimestampParam('time_span_started_less_than', query_params)
            time_span_started_greater_than_or_equal_to = parseTimestampParam('time_span_started_greater_than_or_equal_to', query_params)
        elif "configuration_name" in query_params:
            configuration_name = query_params['configuration_name'][0]
            if configuration_name in os.environ:
                query_text = os.environ[configuration_name]
                time_span_started_less_than = parseTimestampParam('time_span_started_less_than', os.environ)
                time_span_started_greater_than_or_equal_to = parseTimestampParam('time_span_started_greater_than_or_equal_to', os.environ)
            else:
                raise RuntimeError("Configuration param doesn't exist: " + configuration_name)
        else:
            raise RuntimeError("No valid parameters specified, you need to specify one of the following paramaters:\nquery_result_name, query_tql, configuration_name")
    except Exception as e:
        logging.getLogger().error("Error occured while parsing parameters: ", e)
        return response.Response(ctx, status_code=400, response_data=json.dumps({"code": 400, "message": str(e)}, sort_keys=True, 
        indent=2, separators=(',', ': ')), headers={"Content-Type": "application/json"})

    apm_domain_id = os.environ['apm_domain_id']

    apm_traces_client = get_traces_client()

    query_response = apm_traces_client.query(apm_domain_id=apm_domain_id,
                                            query_details=oci.apm_traces.models.QueryDetails(query_text=query_text),
                                            time_span_started_greater_than_or_equal_to=datetime.datetime.fromtimestamp(time_span_started_greater_than_or_equal_to),
                                            time_span_started_less_than=datetime.datetime.fromtimestamp(time_span_started_less_than),
                                            limit=900)
    
    if is_timeseries_data(query_response.data):
        result = transform_time_series_data(query_response.data)
    else:
        result = transform_data(query_response.data)
    
    result = json.dumps(result, sort_keys=True, indent=2, separators=(',', ': '))

    return response.Response(
        ctx, response_data=result,
        headers={"Content-Type": "application/json"}
    )

def parseTimestampParam(param_name: str, params: dict):
    param_result = 0

    if param_name in params:
        if params[param_name].isdigit():
            param_result = int(params[param_name]) / 1000.0
        elif params[param_name][0].isdigit():
            param_result = int(params[param_name][0]) / 1000.0
        else:
            raise TypeError("Error parsing param '" + param_name + "', please provide a valid timestamp")
    else:
        logging.getLogger().warning("Parameter '" + param_name + "' is missing")
    
    return param_result
    

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

### Invoke this function using the code bellow, set the query name and apm_domain_id and also make sure you use the correct code at the method 'get_traces_client'
# query_name = ""
# apm_domain_id = ""

# os.environ["apm_domain_id"] = apm_domain_id
# handler(ctx = InvokeContext("app_id", "app_name", "fn_id", "fn_name", "call_id", request_url="/query?query_result_name=" + query_name))
