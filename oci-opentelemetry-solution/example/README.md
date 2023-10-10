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
   <br>
   npm install opentelemetry
   <br>
   npm install @opentelemetry/sdk-node
   <br>
   npm install @opentelemetry/auto-instrumentations-node
   <br>
3. Copy tracing.js to the server directory and add APM endpoint and data key 
4. Modify package.json to change start to include tracing.js as well —> node -r ./tracing.js server.js
5. Copy app-rum.js to client/public directory with APM endpoint and data key 
6. Edit index.html to include apm-rum.js file 
<script src="./apm-rum.js"></script> 
<script async crossorigin="anonymous" src="https://aaaadcdobxuhuaaaaaaaaacc74.apm-agt.us-ashburn-1.oci.oraclecloud.com/static/jslib/apmrum.min.js"></script>   


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



