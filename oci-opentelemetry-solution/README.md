OCI Observability & Management for the MERN Stack

# MERN Stack Monitoring in OCI
The included files will allow you to monitor your MERN application with:
 1. End-to-end traces uploaded to OCI APM
 2. Custom metrics uploaded to OCI APM
 3. Application logs uploaded to OCI Logging Analytics

    <img width="1017" alt="Screen Shot 2023-08-30 at 11 45 54 AM" src="https://github.com/zkhader/oci-observability-and-management/assets/14898804/d02e48a9-8c90-4c3c-bfeb-92819e41e6d3">



# Step 1: Create an APM Domain in OCI
Follow the documentation to create your domain
https://docs.oracle.com/en-us/iaas/application-performance-monitoring/doc/create-apm-domain.html

- Go to the APM Administration page (Main OCI menu --> Observability & Management --> Application Performance Management --> Administration
- Click on "Create APM Domain" and provide a domain name
  
  <img width="1506" alt="Screenshot 2023-10-10 at 3 00 18 PM" src="https://github.com/zkhader/oci-observability-and-management/assets/14898804/8b5cc430-36fe-40fd-b1e3-1f0ba8af76e6">



Take note of the follwoing:
 1. Data upload endpoint
 2. Public data key
 3. Private data key

- You can find this data in your APM domain's page

  <img width="1507" alt="Screenshot 2023-10-10 at 3 01 11 PM" src="https://github.com/zkhader/oci-observability-and-management/assets/14898804/58a7aa34-ab28-48a2-80b0-65f2a65745e0">



# Step 2: Add the files from the repo to your project
In you server's directory, add metrics.js, ./tracing.js, and ocilogginganalytics.js.


metrics.js file: 
 - Provide your data upload endpoint and private key.
   
   <img width="519" alt="Screenshot 2023-10-10 at 2 50 28 PM" src="https://github.com/zkhader/oci-observability-and-management/assets/14898804/13a0aecd-f23a-4bf0-b947-2d1a05be2724">


tracing.js file: 
 - You can either use the OTEL Collector or the APM Collector to send traces
 - Provide the OTEL collector data upload endpoint if using the OTEL Collector
 - Provide your data upload endpoint and private key if using the APM Collector

   <img width="592" alt="Screenshot 2023-10-10 at 3 17 26 PM" src="https://github.com/zkhader/oci-observability-and-management/assets/14898804/08116128-2cd1-490f-a8f6-8439e0e8875f">



Next, install the required dependencies
```
npm install
```

Add the apm-rum.js file to your client-end directory and reference it in your webpages:

```
<script src="./apm-rum.js"></script>
<script async crossorigin="anonymous" src="[DATA UPLOAD ENDPOINT]/static/jslib/apmrum.min.js"></script>
```

apm-rum.js file:
 - Provide your data upload endpoint, public data key, along with the naming convention you would like to use

   <img width="480" alt="Screenshot 2023-10-10 at 3 18 08 PM" src="https://github.com/zkhader/oci-observability-and-management/assets/14898804/17df1a77-6522-41ac-b931-05253c7fd2f1">



Make sure to run the metric and tracing files alog with your server 
```
node -r ./metrics.js -r ./tracing.js server.js
```

