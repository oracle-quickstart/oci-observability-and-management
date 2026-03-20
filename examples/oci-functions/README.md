# OCI Functions Terraform Modern Example

This is a OCI (Oracle Cloud Infrastructure) Functions Hello World terraform automation. It creates all the necessary OCI resources (Compartment, User Groups, Users, VCN, Subnets etc..) required including OCI functions application and function and finally invokes it. All this is done using terraform.

## What this example creates

- 1 VCN
- 1 internet gateway
- 1 public route table
- 1 public security list
- 1 public subnet
- 1 OCI Functions application
- 1 OCI Function

## Prerequisites

1. Terraform 1.5+ installed
2. OCI account and target compartment
3. OCI credentials configured for Terraform (OCI CLI config file or OCI environment variables)
4. A function image already pushed to OCIR

You can validate OCI authentication quickly with:

```bash
oci iam region-subscription list --tenancy-id <your-tenancy-ocid>
```

## Prepare variables

Copy and edit the sample variable file:

```bash
cp terraform.tfvars.example terraform.tfvars
```

Required values:

- `tenancy_ocid`
- `compartment_ocid`
- `region`
- `function_image`

## Deploy

Run from this folder:

```bash
terraform init
terraform plan
terraform apply
```

## Post-deploy verification

Get outputs:

```bash
terraform output
```

Check function metadata with OCI CLI:

```bash
oci fn function get --function-id "$(terraform output -raw function_id)"
```

## Build and push an image (example flow)

If you already have an image in OCIR, keep using it. If not, use these steps to create one.

1. Set image path once so Docker push and Terraform use the same value:

```bash
export IMAGE_PATH=<region-key>.ocir.io/<your-namespace>/appdev/hello-python:0.0.1
```

2. Set Fn context for your OCI region:

```bash
fn list context
fn use context <your-region-identifier>
```

3. Set compartment and registry on the context:

```bash
fn update context oracle.compartment-id <your-compartment-ocid>
fn update context registry <region-key>.ocir.io/<your-namespace>
```

4. Generate an OCIR auth token for your user, then log in:

```bash
docker login -u '<your-namespace>/oracleidentitycloudservice/<your-email>' <region-key>.ocir.io
```

5. Create a function scaffold and move into it:

```bash
fn init --runtime python hello-python
cd hello-python
```

6. Create a file named `Dockerfile` and add:

```dockerfile
FROM oraclelinux:7-slim
WORKDIR /function
RUN groupadd --gid 1000 fn && adduser --uid 1000 --gid fn fn

RUN yum-config-manager --disable ol7_developer_EPEL && \
    yum-config-manager --enable ol7_optional_latest && \
    yum -y install python3 oracle-release-el7 && \
    rm -rf /var/cache/yum

ADD . /function/
RUN pip3 install --no-cache --no-cache-dir -r requirements.txt
RUN rm -fr /function/.pip_cache ~/.cache/pip requirements.txt func.yaml Dockerfile README.md

ENV PYTHONPATH=/python
ENTRYPOINT ["/usr/local/bin/fdk", "/function/func.py", "handler"]
```

7. Build and push the image to OCIR:

```bash
docker build . -t "$IMAGE_PATH"
docker push "$IMAGE_PATH"
docker pull "$IMAGE_PATH"
```

8. Use the same image URI in `terraform.tfvars`:

```hcl
function_image = "<region-key>.ocir.io/<your-namespace>/appdev/hello-python:0.0.1"
```

Example image format:

```text
iad.ocir.io/<namespace>/hello-world:1.0.0
```

## Security and operations notes

- This sample uses a public subnet to simplify internet-access testing flows.
- Terraform state uses the default local backend for simplicity.
- For team usage or production, use a remote backend and locking.
- For stricter production posture, move this pattern to a private subnet with explicit egress controls.
