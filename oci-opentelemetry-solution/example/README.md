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

### Enable Logging Analytics
1. Go to the server directory
   ```
   npm install undici
   npm install bunyan
   npm install oci-loganalytics

   ```
   <br>

2. Copy the ocilogginganalytics.js file to the server directory and edit the file to update the parameters mentioned below. 
> Note: Detailed Logging Analytics configuration can be found in oci-observability-and-management/oci-opentelemetry-solution/

[PATH]/config - Path to config file
[PROFILE] - Profile in config file to be used for OCI authentication
[NAMESPACE] - Namespace
[UPLOADNAME] - User defined name for uploads
[LOGSOURCENAME] - Log Source Name created in OCI logging analytics
[LOGGROUPID] - Log Group ID created in Logging analytics to group the log messages
[BUFFERLENGTH] - Buffer size (number of log messages to store)
[FLUSHINTERVAL] – Flush internal in milliseconds to flush messages from buffer and send it to OCI LA
[LOGGERNAME] – user defined name to initialize the bunyan logger

3. Modify the application source files to include log messages as shown below 

```
const ocilog= require('../ocilogginganalytics');
var log=ocilog.getlogger();

log.debug("Debug message");
log.warn("Warning message");
log.info("Informational message");
log.error("Error message");
```

Lets modify the file server/routes/items.js to initialize the logger and include log messages as shown below. 

```
// Copyright (c) 2023 Oracle and/or its affiliates.
// Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

const express = require('express');
const router = express.Router();
const Item = require('../models/Item');
const ocilog= require('../ocilogginganalytics');
var log=ocilog.getlogger();

// Define CRUD routes here (GET, POST, PUT, DELETE)
// Example routes:

// Get all items
router.get('/', (req, res) => {
  log.debug("Inside get records method");
  Item.find()
    .then((items) => res.json(items))
    .catch((err) => res.status(400).json('Error: ' + err));
});

// Add a new item
router.post('/', (req, res) => {
  log.debug("Inside add record method");
  const newItem = new Item({
    name: req.body.name,
    description: req.body.description,
  });

  newItem
    .save()
    .then(() => res.json('Item added!'))
    .catch((err) => res.status(400).json('Error: ' + err));
});

// Update an item
router.put('/:id', (req, res) => {
  log.debug("Inside update record method");
  Item.findByIdAndUpdate(req.params.id, req.body, { new: true })
    .then(() => res.json('Item updated!'))
    .catch((err) => res.status(400).json('Error: ' + err));
});

// Delete an item
router.delete('/:id', (req, res) => {
  log.debug("Inside delete record method");
  Item.findByIdAndDelete(req.params.id)
    .then(() => res.json('Item deleted.'))
    .catch((err) => res.status(400).json('Error: ' + err));
});

module.exports = router;

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

Application traces and metrics will now be sent to OCI APM and application logs will now be sent to OCI Logging Analytics.

### OCI APM - Traces and Spans

![Image-APM](https://github.com/zkhader/oci-observability-and-management/assets/14898804/7ff956f9-d668-4dd2-8cac-79e29562f96f)



