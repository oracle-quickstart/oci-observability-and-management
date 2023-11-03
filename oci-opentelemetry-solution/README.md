OCI Observability & Management for the MERN Stack

# MERN Stack Monitoring in OCI
The included files will allow you to monitor your MERN application with:
 1. End-to-end traces uploaded to OCI APM
 2. Custom metrics uploaded to OCI APM
 3. Application logs uploaded to OCI Logging Analytics

    <img width="1134" alt="Screenshot 2023-10-10 at 3 27 28 PM" src="https://github.com/zkhader/oci-observability-and-management/assets/14898804/5393f06f-030b-4ed1-88bb-fab284a83937">




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


# Step 2: Create Logging Anaytics configuration 

1. Create API signing key
   * Login to OCI console → User → User settings
   * Select API Keys under Resources
   * Click on Add API Key → Generate API Key Pair → Click on Download Private Key & then Add
   * Copy the content from Configuration File Preview & Close
     <br>
     <img width="720" alt="1 UserProfile" src="https://github.com/Anand-GitH/oci-observability-and-management/assets/60418080/160bb472-c96a-4727-970f-8826f19a7827">

2. Create a Configuration File
   * Create a directory .oci and a config file with content from configuration file preview and path to private key file

   ```
   config
   [DEFAULT]
   user=ocid1.user.oc1..aaaaaaaamfy2qbkj7udfwmep34njicnu6skbzuddb52w4v4d7r2oepa3x5ya
   fingerprint=8a:ff:62:12:05:c8:29:80:4a:3d:0b:54:ac:86:85:e2
   tenancy=ocid1.tenancy.oc1..aaaaaaaa5s2vdjjrydixjulorcwozffbpna37w5a35p3jhgpyshlkmio6oiq
   region=us-ashburn-1
   key_file=~/.oci/oci-priv-key.pem
   ```

3. Create a Log Parser
   * Observability & Management → Logging Analytics → Administration
   * Click on Parsers → Create Parser → Choose JSON type
   * Enter example JSON log content it will parse and extract fields and map it to specific field names as needed and click save changes.

   LogRecord
   ```
   {"name":"OCILogger","hostname":"emcc.marketplace.com","pid":12586,"level":50,"msg":"Inside delete method:Cannot Delete with id 649b4ac1883092297279051b. Maybe id 
   is wrong","time":"2023-07-10T07:02:13.678Z","src":{},"v":0,"trace_id":"5941ccd308fcb49e30b3ebfcffcff38f","span_id":"0bed4a8c3b33d48e","trace_flags":"01"}
   ```
   <br>
   <img width="1285" alt="2 Parser" src="https://github.com/Anand-GitH/oci-observability-and-management/assets/60418080/ebaaa401-bc7e-4e6b-a220-7b9a441bddcc">

4. Create a Log Source
   * Logging Analytics → Administration → Sources → Create Source
   * Source Type → File
   * Entity Types → Host (Linux)
   * Select Specific Parser → Select the parser created
   * Click on Create Source
     
     <br>  
     <img width="1260" alt="3 LogSource" src="https://github.com/Anand-GitH/oci-observability-and-management/assets/60418080/f967a34d-3835-4126-a5c8-7ffe8f1b267b">

   
5. Create a Log Group
   * Logging Analytics → Administration → Log Groups → Create Log Group
   * Provide Log Group Name and description → click create
  
     <br>  
     <img width="789" alt="4 LogGroup" src="https://github.com/Anand-GitH/oci-observability-and-management/assets/60418080/32cbdd5f-ce3b-4bb3-bce1-96e6e2a4973e">
     <br>
   > Make a note of OCID of Log Group which will be used later
     <br>
     <img width="1099" alt="5 LogGroup-2" src="https://github.com/Anand-GitH/oci-observability-and-management/assets/60418080/8fa7770e-a9a5-44a5-acd7-c6882085a46f">


6. Get the Namespace Details
   * Goto Identity →  Compartments → Click on compartment where the log source is created → Copy OCID of the compartment
     <br>
     <img width="998" alt="6 Compartment-OCID-2" src="https://github.com/Anand-GitH/oci-observability-and-management/assets/60418080/06b6761e-a0d1-4312-afcb-d514d2a2343c">


   * Now launch cloud shell and execute below command to get the namespace  
   ```
   oci os ns get -c compartmentID 
   ```  
     <br>
     <img width="1231" alt="7 Namespace" src="https://github.com/Anand-GitH/oci-observability-and-management/assets/60418080/4c28b966-fe94-477a-97ba-5708a4ea5ecb">


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

ocilogginganalytics.js file: 
 - Edit the file to update the parameters mentioned below   
   [PATH]/config - Path to config file  
   [PROFILE] - Profile in config file to be used for OCI authentication  
   [NAMESPACE] - Namespace  
   [UPLOADNAME] - User defined name for uploads  
   [LOGSOURCENAME] - Log Source Name created in OCI logging analytics  
   [LOGGROUPID] - Log Group ID created in Logging analytics to group the log messages  
   [BUFFERLENGTH] - Buffer size (number of log messages to store)  
   [FLUSHINTERVAL] – Flush internal in milliseconds to flush messages from buffer and send it to OCI LA  
   [LOGGERNAME] – user defined name to initialize the bunyan logger  

   <br>
   <img width="1116" alt="image" src="https://github.com/Anand-GitH/oci-observability-and-management/assets/60418080/cca9667b-caa8-46fb-af68-09e9a5ecfd7e">
   <br>
   <img width="1056" alt="image" src="https://github.com/Anand-GitH/oci-observability-and-management/assets/60418080/bbf57fd6-32d8-424b-85ca-eeab8f745d82">
   <br>
   <img width="973" alt="image" src="https://github.com/Anand-GitH/oci-observability-and-management/assets/60418080/f5355466-1864-46ac-a394-6f4d767f9b65">
   <br>
   <img width="986" alt="image" src="https://github.com/Anand-GitH/oci-observability-and-management/assets/60418080/d1143df6-dc28-40cc-b067-3bab0ba7eafe">


 - Modify the application source files to initialize the logger and add log messages as shown below 

   ```
   const ocilog= require('../ocilogginganalytics');
   var log=ocilog.getlogger();

   log.debug("Debug message");
   log.warn("Warning message");
   log.info("Informational message");
   log.error("Error message");
   ```
   <br>
   <img width="993" alt="image" src="https://github.com/Anand-GitH/oci-observability-and-management/assets/60418080/7a8f59e3-27b2-48ba-814c-283db31ab2b0">
   <br>
   <img width="986" alt="image" src="https://github.com/Anand-GitH/oci-observability-and-management/assets/60418080/0459d163-0e61-41a7-b710-a4467858b8f4">



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

