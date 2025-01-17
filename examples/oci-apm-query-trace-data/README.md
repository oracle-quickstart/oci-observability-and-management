# OCI APM trace querier function setup

This is a OCI (Oracle Cloud Infrastructure) APM trace querier function setup which at the end will crate aan OCI function that can be queried to get trace data in an easy to use format, the function code is also available if the default format does notcater to your needs. 

This project aims to create all the necessary OCI resources (Compartment, User Groups, Users, VCN, Subnets etc..) required including creating the image, the OCI functions application and function and finally invoking it. And all of this is done using terraform.

In this example we will be creating:

* 1 x Container registry to store the image
* 1 x Virtual Cloud Network (VCN)
* 1 x Subnet (Public)
* 1 x Internet Gateway for Public Subnet
* 1 x OCI application
* 1 x OCI function
* Create and push the function's image to the registry
* Create Functions Policies. 

## Prerequisites

Before you deploy this function for use, make sure you have run step C - 3 of the [Oracle Functions Quick Start Guide for Cloud Shell](https://www.oracle.com/webfolder/technetwork/tutorials/infographics/oci_functions_cloudshell_quickview/functions_quickview_top/functions_quickview/index.html), the auth token is required to push the image to the repository.

    C - 3. Generate auth token

## Terraform Deployment

# Deploy to OCI with one click

Cick on button bellow to deploy the function to OCI using the resource manager, some values will be prepopulated:

[![Deploy to Oracle Cloud](https://oci-resourcemanager-plugin.plugins.oci.oraclecloud.com/latest/deploy-to-oracle-cloud.svg)](https://cloud.oracle.com/resourcemanager/stacks/create?zipUrl=https://github.com/iliassox/oci-observability-and-management/releases/download/0.1/apm-trace-querier-release.zip) 

# Deploy using local dev environment:

## Preparation:

Prepare one variable file named `terraform.tfvars` with the required information.

The contents of `terraform.tfvars` should look something like the following:

```
tenancy_ocid = "ocid1.tenancy.oc1..xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
compartment_ocid = "ocid1.compartment.oc1..xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
region = "us-ashburn-1"
current_user_ocid = "ocid1.user.oc1..xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
user_auth_token = "xxxxxxxxxxxxxxx" # Replace with your own auth token
function_invoke_body = ""
```

## Deploying the function:

Apply the changes using the following commands:

```
  terraform init
  terraform plan
  terraform apply
```

## Output

```
Outputs:

function_response = "" # Should return query results as an array
```

Sometimes it can take a bit longer for the function to be ready, when that happens you can call the funtion in cloud shell using this line :

    echo -n '{
      "apm_domain_id":"ocid1.tenancy.oc1..xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx",
      "query_text":"",
      "query_name":"",
      "time_span_started_greater_than_or_equal_to":"2015-09-04T06:18:46.305Z",
      "time_span_started_less_than":"2033-08-18T22:58:41.091Z"
    }' | fn invoke apm-trace-querier-app apm-trace-querier

note: To invoke the function, you can eiher specify the query text which is the full query, or just the query name of a backgroud query which will be used, if you specify both, the query text will be used.
