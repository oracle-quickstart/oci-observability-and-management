# OCI Logging Analytics Quick Start

## Introduction

The quickstart steps for logging analytics are defined here:
https://docs.oracle.com/en/cloud/paas/logging-analytics/logqs/

In this example we will automate the following:

* Create Logging Analytics Compartment (Optional). Skip if the compartment exists.
* Create Logging Analytics User Group (Optional)
* Create Logging Analytics Users (Optional). Skip if the user already exists.
* Create Dynamic Groups. 
* Create Logging Analytics Policies. This is pre-defined.
* Onboard Logging Analytics.

## Using this example

1. Prepare one variable file named `terraform.tfvars` with the required IAM information. The contents of `terraform.tfvars` should look something like the following (or copy and re-use the contents of `terraform.tfvars.template`:

```
### TENANCY DETAILS

# Get this from the bottom of the OCI screen (after logging in, after Tenancy ID: heading)
tenancy_id="<tenancy OCID"
# Get this from OCI > Identity > Users (for your user account)
user_id="<user OCID>"

# the fingerprint can be gathered from your user account (OCI > Identity > Users > click your username > API Keys fingerprint (select it, copy it and paste it below))
fingerprint="<PEM key fingerprint>"
# this is the full path on your local system to the private key used for the API key pair
private_key_path="<path to the private key that matches the fingerprint above>"

# region (us-phoenix-1, ca-toronto-1, etc)
region="<your region>"
```

2. Refer and edit your `main.tf` file. Look for "< >" brackets and add the details accordingly.

3. Then apply the example using the following commands:

```
$ terraform init
$ terraform plan
$ terraform apply
```

Note: To further install a management agent or ingest the data refer the quick start document to complete those manual steps
https://docs.oracle.com/en/cloud/paas/logging-analytics/logqs

For on demand upload via OCI CLI, refer: https://docs.oracle.com/en-us/iaas/logging-analytics/doc/demand-upload-using-cli.html

## Testing

This example was tested on (Use v0.14.3 and above):
```
$ terraform version
Terraform v0.14.3
```