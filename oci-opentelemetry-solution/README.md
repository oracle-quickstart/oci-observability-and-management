OCI Observability & Management for the MERN Stack

# MERN Stack Monitoring in OCI
The included files will allow you to monitor your MERN application with:
 1. End-to-end traces uploaded to OCI APM
 2. Custom metrics uploaded to OCI APM
 3. Application logs uploaded to OCI Logging Analytics


# Step 1: Create an APM Domain in OCI
Follow the documentation to create your domain
https://docs.oracle.com/en-us/iaas/application-performance-monitoring/doc/create-apm-domain.html

Take note of the follwoing:
 1. Data upload endpoint
 2. Public data key
 3. Private data key


# Step 2: Add the files from the repo to your project
In you server's directory, add metrics.js, ./tracing.js, and ocilogginganalytics.js.


metrics.js file: 
 - Provide your data upload endpoint and private key.

tracing.js file: 
 - You can either use the OTEL Collector or the APM Collector to send traces
 - Provide the OTEL collector data upload endpoint if using the OTEL Collector
 - Provide your data upload endpoint and private key if using the APM Collector


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


Make sure to run the metric and tracing files alog with your server 
```
node -r ./metrics.js -r ./tracing.js server.js
```

