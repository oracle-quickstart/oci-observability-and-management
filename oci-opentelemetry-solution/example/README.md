# Sample MERN Application
Product Inventory Application

Steps to start the application:
1. cd server —> Modify server.js to include the mongoDB details 
2. npm install
3. npm start 
4. cd client
5. npm install
6. npm start   --> application launches on - http://localhost:3001


Now lets enable APM and open telemetry  
1. Goto server directory   
    npm install opentelemetry 
    npm install @opentelemetry/sdk-node 
    npm install @opentelemetry/auto-instrumentations-node  
2. Copy tracing.js to the server directory and add APM endpoint and data key 
3. Modify package.json to change start to include tracing.js as well —> node -r ./tracing.js server.js
4. Copy app-rum.js to client/public directory with APM endpoint and data key 
5. Edit index.html to include apm-rum.js file 
<script src="./apm-rum.js"></script> 
<script async crossorigin="anonymous" src="https://aaaadcdobxuhuaaaaaaaaacc74.apm-agt.us-ashburn-1.oci.oraclecloud.com/static/jslib/apmrum.min.js"></script>   

Now lets enable Logging Analytics 
1. Goto server directory
2. npm install undici
3. npm install oci-loganalytics
4. npm install bunyan
5. Copy ocilogginganalytics.js to the server directory
6. Now modify the code in ocilogginganalytics.js to fill in all the parameters : Refer document (LoggingAnalytics.pdf)

    1. [PATH]/config - Path to config file 
    2. [PROFILE] - Profile in config file to be used for OCI authentication 
    3. [NAMESPACE] - Namespace 
    4. [UPLOADNAME]- User defined name for uploads 
    5. [LOGSOURCENAME]- Log Source Name created in OCI logging analytics
    6. [LOGGROUPID]- Log Group ID created in Logging analytics to group the log messages
    7. [BUFFERLENGTH] - Buffer size (number of log messages to store)
    8. [FLUSHINTERVAL] – Flush internal in milliseconds to flush messages from buffer and send it to OCI LA
    9. [LOGGERNAME] – user defined name to initialize the bunyan logger 


7. goto application files to initialize logger to use new LA logging 
const ocilog= require('../ocilogginganalytics');
var log=ocilog.getlogger();

now log.debug, log.warn, log.warn, log.info will start sending logs to OCI logging analytics once the application started 


Now lets start the application 

Terminal 1:
1. cd server 
2. npm start

Terminal 2:
1. cd client
2. npm start

Application traces, metrics and logs are all sent to OCI. Traces and Metrics to OCI APM and logs to OCI Logging analytics. 

OCI APM - Traces and Spans
<img width="1429" alt="image" src="https://github.com/Anand-GitH/MERN_PROD_INV/assets/60418080/0733860d-6509-4b5a-8788-0773d84d8782">


OCI Logging Analytics - logs 
<img width="1429" alt="image" src="https://github.com/Anand-GitH/MERN_PROD_INV/assets/60418080/0280576c-6ff2-4758-9d5c-382677004af3">

 
