// Copyright (c) 2023 Oracle and/or its affiliates.
// Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

'use strict'
const process = require('process');
const opentelemetry = require('@opentelemetry/sdk-node');
const { getNodeAutoInstrumentations } = require('@opentelemetry/auto-instrumentations-node');
const { OTLPTraceExporter } = require('@opentelemetry/exporter-trace-otlp-http');
const { Resource } = require('@opentelemetry/resources');
const { SemanticResourceAttributes } = require('@opentelemetry/semantic-conventions');
const { MongoDBInstrumentation } = require('@opentelemetry/instrumentation-mongodb')

// Collector Settings (APM Collector - traces endpoint)
  const exporterOptions = {
    url: "[DATA UPLOAD ENDPOINT]/20200101/opentelemetry/private/v1/traces",
    headers: {"Authorization": "dataKey [PRIVATE KEY]"},
  }

// Collector Settings (OpenTelemetry Collector - traces endpoint)
  /*const exporterOptions = {
    url: "http://[OTEL COLLECTOR ENDPOINT]/v1/traces",
  }*/
    

//For troubleshooting, set the log level to DiagLogLevel.DEBUG (uncomment the two lines below)

/*const { diag, DiagConsoleLogger, DiagLogLevel } = require('@opentelemetry/api');
diag.setLogger(new DiagConsoleLogger(), DiagLogLevel.DEBUG);*/


const traceExporter = new OTLPTraceExporter(exporterOptions);
const sdk = new opentelemetry.NodeSDK({
   traceExporter,
   
   // Include required instrumentations
   instrumentations: [getNodeAutoInstrumentations({
      '@opentelemetry/instrumentation-fs': {enabled: false,},}),
    new MongoDBInstrumentation({enhancedDatabaseReporting: true,})]
    ,

  resource: new Resource({
      [SemanticResourceAttributes.SERVICE_NAME]: 'crud_app'
      })
});

// initialize the SDK and register with the OpenTelemetry API
// this enables the API to record telemetry

sdk.start()

// gracefully shut down the SDK on process exit
process.on('SIGTERM', () => {
   sdk.shutdown()
 .then(() => console.log('Tracing terminated'))
 .catch((error) => console.log('Error terminating tracing', error))
 .finally(() => process.exit(0));
 });
