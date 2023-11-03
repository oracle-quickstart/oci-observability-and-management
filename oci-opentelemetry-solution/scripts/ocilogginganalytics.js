// Copyright (c) 2023 Oracle and/or its affiliates.
// Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

//Connection timeout for the http requests
const {fetch, setGlobalDispatcher, Agent } = require('undici')
setGlobalDispatcher(new Agent({ connect: { timeout: 60_000 } }) )

//Send logs from MERN application to OCI Logging Analytics using this file
//Requires three libraries
//oci-loganalytics - to initialize the log analytics client and send log message to OCI LA
//oci-common - for reading the config file
//bunyan - to format the log messages into JSON format

"use strict";
const loganalytics = require("oci-loganalytics");
const common = require("oci-common");
var bunyan = require('bunyan');

//Class LogBuffer allows to buffer log messages and sends logs to logfunction based on buffersize and flushinterval
//buffersize : Number of messages the buffer can hold and when it reaches this limit it flushes all messages by calling logfunction
//flushInterval: To flush messages from buffer at regular intervals
//logFunction : function which needs to be called while flushing messages from buffer - here we will call ociloganalytics
class LogBuffer {
  constructor(bufferSize, flushInterval, logFunction) {
    this.bufferSize = bufferSize;
    this.flushInterval = flushInterval;
    this.logFunction = logFunction;
    this.buffer = [];

    // Set up a timer to flush the buffer at regular intervals
    this.flushTimer = setInterval(this.flush.bind(this), this.flushInterval);
  }

  log(message) {

    this.buffer.push(message);
    // Check if the buffer size has been reached, and flush if necessary
    if (this.buffer.length >= this.bufferSize) {
      this.flush();
    }
  }

  flush() {

    if (this.buffer.length === 0) {
      return;
    }

    // Concatenate the buffered log messages and call the log function
    const logMessage = this.buffer.join('\n');
    this.logFunction(logMessage);

    // Clear the buffer
    this.buffer = [];
  }

  close() {
    // Flush any remaining logs and stop the flush timer
    this.flush();
    clearInterval(this.flushTimer);
  }
}

//function to send log messages to OCI logging analytics
function ociloganalytics(data){

//initialization of the OCI logging parameters
//config contains API key and tenancy, user details & profile to use [Infromation can be found while creating API signing keys]
const configurationFilePath = "[PATH]/config"; //path to config file
const configProfile = "[PROFILE]";    //profile in config file to be used for OCI authentication
const provider = new common.ConfigFileAuthenticationDetailsProvider(
  configurationFilePath,
  configProfile
);

//Using node js OCI logging analytics client to send log message to the LA

(async () => {
  try {
    // Create a service client
    const client = new loganalytics.LogAnalyticsClient({ authenticationDetailsProvider: provider }, {
      retryConfiguration : {
         delayStrategy : new common.FixedTimeDelayStrategy(5),
         terminationStrategy : new common.MaxTimeTerminationStrategy(30),
         retryCondition : (error) => { return error.statusCode >= 500;
      }
    }});

    var bodytext = Buffer.from(data, 'utf8');
    // Create a request and dependent object(s).
    const uploadLogFileRequest = {
      namespaceName: "[NAMESPACE]",        //get the namespace using the command on cloud shell oci os ns get -c compartmentID
      uploadName: "[UPLOADNAME]",          //upload name - user defined string to identify specific upload of log messages
       logSourceName: "[LOGSOURCENAME]",   //Log Source Name created in OCI logging analytics
      filename: "[LOGFILENAME]",           //Log file name to indicate log messages are related to specific log file
      opcMetaLoggrpid: "[LOGGROUPID]",     //Log Group ID created in Logging analytics to group the log messages
      uploadLogFileBody: bodytext,         //Log message in the utf8 format
    };

    //Send upload log file request to the OCI logging analytics
    try{
    const uploadLogFileResponse = await client.uploadLogFile(uploadLogFileRequest);
    } catch (err) {
        console.log('requestId: ', err.opcRequestId);
    }
  } catch (error) {
    console.log("uploadLogFile Failed with error  " + JSON.stringify(error));
  }
})();

}

//initializing the log buffer
//Buffer size - 30 messages
//flush intervale set to 60000 mili seconds = 60 seconds
//calls ociloganalytics function to flush messages by sending messages to logging analytics
const buffer = new LogBuffer([BUFFERLENGTH], [FLUSHINTERVAL] , ociloganalytics);

//extending different log levels - info, debug, error and warn
function InfoStream() {}

InfoStream.prototype.write = function(data) {
  buffer.log(data)
}

function DebugInfoStream() {}

DebugInfoStream.prototype.write = function(data) {
  buffer.log(data)
}

function ErrorInfoStream() {}

ErrorInfoStream.prototype.write = function(data) {
  buffer.log(data)
}

function WarnInfoStream() {}

WarnInfoStream.prototype.write = function(data) {
  buffer.log(data)
}

//Creating bunyan logger with custom streams
module.exports = {
  getlogger: function () {
    var log = bunyan.createLogger({
      src: true,
      name: "[LOGGERNAME]",
      streams: [{
        level: "info",
        stream: new InfoStream()
      },
      {
        level: "debug",
        stream: new DebugInfoStream()
      },
      {
        level: "error",
        stream: new ErrorInfoStream()
      },
      {
      level: "warn",
      stream: new WarnInfoStream()
      }]
    })

    return log;
  }
};
