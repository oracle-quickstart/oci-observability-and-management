# ebs-sensors
*This doc is intended for QA only at this point. It will be modified for end-users soon.
This solution provides an easy way to monitor EBS Database. 
As part of this deployment, a compute instance is created and MACS agent is configured to collect log data. Users can select the EBS products that they are using and EBS sensor sources for those products are created. EBS Database entity and source-entity associations are also created.  

## Prerequisites
- VCN and subnet from where database can be accessed.
- Database password should be stored as a vault secret.
- Quota to create the following resources: 1 Compute instance,  1 dynamic group, 1 policy
- Store EBS DB password in OCI Vault in base encoded form. 
- Store schedule file in OCI Object Storage bucket. 

If you don't have the required permissions and quota, contact your tenancy administrator. See [Policy Reference](https://docs.cloud.oracle.com/en-us/iaas/Content/Identity/Reference/policyreference.htm), [Service Limits](https://docs.cloud.oracle.com/en-us/iaas/Content/General/Concepts/servicelimits.htm), [Compartment Quotas](https://docs.cloud.oracle.com/iaas/Content/General/Concepts/resourcequotas.htm).

## Deploy Using Oracle Resource Manager

1. Click [![Deploy to Oracle Cloud](https://oci-resourcemanager-plugin.plugins.oci.oraclecloud.com/latest/deploy-to-oracle-cloud.svg)]()

#    If you aren't already signed in, when prompted, enter the tenancy and user credentials.

2. Review and accept the terms and conditions.

3. Select the region where you want to deploy the stack.

4. Follow the on-screen prompts and instructions to create the stack.

5. After creating the stack, click **Terraform Actions**, and select **Plan**.

6. Wait for the job to be completed, and review the plan.

    To make any changes, return to the Stack Details page, click **Edit Stack**, and make the required changes. Then, run the **Plan** action again.

7. If no further changes are necessary, return to the Stack Details page, click **Terraform Actions**, and select **Apply**.
