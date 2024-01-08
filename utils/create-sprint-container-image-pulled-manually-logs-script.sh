#!/bin/bash

echo '
{
    "name": "fluentd",
    "ready": true,
    "restartCount": 0,
    "image": "iad.ocir.io/namespace/fluentd_loganalytics_1:latest",
    "imageID": "docker-pullable://iad.ocir.io/ns/fluentd_loganalytics_1@sha256:123456712345677c2b71e6e632ea376466d80997067e78e522862a62d58922fa",
    "containerID": "docker://090458514f4d8ba69844f4cdcd55128d576ac6777e5937ca16f9e319fedb2536",
    "started": true,
    "initContainer": false,
    "state": {
        "status": "running",
        "startedAt": "2021-08-13T12:21:35Z"
    },
    "lastState": {},
    "podName": "fluentd-g42bx",
    "nodeName":"10.20.10.14",
    "namespaceName":"kube-system"
}';