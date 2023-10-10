# Sample MERN Application
Product Inventory Application

### Steps to Start the Application
1. cd server —> Modify server.js to include the MongoDB details 
```
   npm install
   npm start
```
2. cd client
```
   npm install
   npm start
```

3. Application launches on - http://localhost:3001


### Enable APM and OpenTelemetry  
1. Go to the server directory
   ```
   npm install opentelemetry
   npm install @opentelemetry/sdk-node
   npm install @opentelemetry/auto-instrumentations-node
   ```
   <br>
3. Copy the tracing.js and metrics.js files to the server directory and edit the files to include the APM endpoint and data key
4. Modify package.json to change the start command so it includes metrics.js and tracing.js
```
   node -r ./tracing.js -r ./metrics.js server.js
```
6. Copy app-rum.js to client/public directory with the APM endpoint and data key 
7. Edit index.html to include apm-rum.js file

```
<script src="./apm-rum.js"></script> 
<script async crossorigin="anonymous" src="[APM DOMAIN ENDPOINT]/static/jslib/apmrum.min.js"></script>   
```

Now lets start the application:

<ins>Terminal 1:</ins>
```
cd server 
npm start
```

<ins>Terminal 2:</ins>
```
cd client
npm start
```

Application traces and metrics will now be sent to OCI APM. 

### OCI APM - Traces and Spans

![Image-APM](https://github.com/zkhader/oci-observability-and-management/assets/14898804/7ff956f9-d668-4dd2-8cac-79e29562f96f)



