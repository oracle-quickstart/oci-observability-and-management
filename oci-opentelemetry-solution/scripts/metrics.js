'use strict'
const process = require('process');
const { Resource } = require('@opentelemetry/resources');
const { SemanticResourceAttributes } = require('@opentelemetry/semantic-conventions');
const { OTLPMetricExporter } = require('@opentelemetry/exporter-metrics-otlp-http');
const { MeterProvider, PeriodicExportingMetricReader } = require('@opentelemetry/sdk-metrics');
var os = require('os');
const osu = require('node-os-utils')
var getMetrics = require('metrics-os')
const disk = require('diskusage');

// Collector Settings (APM Collector - metrics endpoint)
const collectorOptions = {
   url: '[DATA UPLOAD ENDPOINT]/20200101/opentelemetry/v1/metrics',
   headers: {"Authorization": "dataKey [PRIVATE KEY]"}
};
const metricExporter = new OTLPMetricExporter(collectorOptions);


// Meter provider configuration
const meterProvider = new MeterProvider({
  resource: new Resource({
    [SemanticResourceAttributes.SERVICE_NAME]: 'api-metrics',
  }),
});

meterProvider.addMetricReader(new PeriodicExportingMetricReader({
   exporter: metricExporter,
   exportIntervalMillis: 1000,
 }));

const meter = meterProvider.getMeter('api-exporter-collector');
const attributes = { pid: process.pid, environment: 'staging'};



// Define your meters (4 examples here - CPU utilization, memory utilization, free disk space, and load)
const cpuUtil = meter.createUpDownCounter('cpu_util', {
   description: '% CPU Utilization'
});

const load1m = meter.createUpDownCounter('avg_load_1m', {
   description: 'Average 1m load',
});

const freeDiskSpace = meter.createUpDownCounter('free_disk_space', {
   description: '% Free Disk Space',
});

const memoryUtil = meter.createUpDownCounter('memory_util', {
   description: '% Memory Utilization',
});




console.log("################ Ready to send metrics #################")


// Initialize values for your metrics
var currentCPU = 0.0
var currentAvgLoad = 0.0
var currentDiskMetrics = 0.0
var currentUsedMem = 0.0

// Send data in 60 second intervals
setInterval(() => {

   // Memory Utilization Calculations
   var mem = (Math.round(parseFloat((os.totalmem() - os.freemem())/os.totalmem()) * 100) / 100) * 100
   if(mem != currentUsedMem){
      memoryUtil.add(Math.round((mem - currentUsedMem) * 100) / 100, attributes);
   }
   currentUsedMem = mem

   // CPU Utilization Calculations
   const cpu = osu.cpu
   const count = cpu.count() // 8
   var cpuUtilization
   cpu.usage()
   .then(cpuPercentage => {
      var cpuUtilization = (Math.round(cpuPercentage)/ 100) * 100
      if(cpuUtilization != currentCPU){
         cpuUtil.add(Math.round((cpuUtilization - currentCPU) * 100) / 100, attributes);
      }
      currentCPU = cpuUtilization
   })

   // Average Load (1m) Calculations
   var metrics = getMetrics();
   var load = metrics["load"]["1m"]
   if(load != currentAvgLoad){
      load1m.add(Math.round((load - currentAvgLoad) * 100) / 100, attributes);
   }
   currentAvgLoad = load

   // Disk Metrics Calculations
   disk.check('/', function(err, info) {
      const freePercentage = info.free / info.total;
      var freePrecent = (Math.round(freePercentage * 100) / 100) * 100
      if(freePrecent != currentDiskMetrics){
         freeDiskSpace.add(Math.round((freePrecent - currentDiskMetrics) * 100) / 100, attributes);
      }
      currentDiskMetrics = freePrecent
   });

}, 60000);
