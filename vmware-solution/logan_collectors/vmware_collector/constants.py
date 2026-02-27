#
# Copyright (c) 2026 Oracle, Inc.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#
# constatnts.py
ALARMS_CHECKPOINT_FILE = "alarms_checkpoint.json"
ALARMS_FILE = "collected_alarms.json"
ALARMS_PAYLOAD_FILE = "alarms_payload.json"

# OCI API Call Limits
OCI_RATE_LIMIT_CALLS = 100
OCI_RATE_LIMIT_PERIOD = 60

# Entity Cache TTL
CACHE_TTL_SECONDS = 300

# Checkpoint file to track last processed event
EVENTS_CHECKPOINT_FILE = "events_checkpoint.json"

EVENTS_LOG_FILE = "events.log"
ACTIONS_LOG_FILE = "eventactions.log"
EVENTS_APP_LOG_FILE = "eventapp.log"

# VMware-supported entity types in OCI Log Analytics
SUPPORTED_ENTITY_TYPES = [
    "VMware vSphere VM",
    "VMware vSphere ESXi Host",
    "VMware vSphere Cluster",
    "VMware vSphere Resource Pool",
    "VMware vSphere vCenter",
    "VMware vSphere Data Center",
    "VMware vSphere vApp",
    "VMware vSphere Data Store",
]

# Map internal vCenter entity type names to OCI LA entity type names
VC_TO_OCI_ENTITY_TYPE = {
    "Vmware_CLUSTER": "VMware vSphere Cluster",
    "Vmware_VM_INSTANCE": "VMware vSphere VM",
    "Vmware_ESXI_HOST": "VMware vSphere ESXi Host",
    "VMware_DATA_CENTER": "VMware vSphere Data Center",
    "Vmware_DATASTORE": "VMware vSphere Data Store",
    "Vmware_RESOURCE_POOL": "VMware vSphere Resource Pool",
    "Vmware_VCENTER": "VMware vSphere vCenter",
    "Vmware_ResourcePool": "VMware vSphere Resource Pool"
}


INTERESTED_ENTITY_TYPES = {
    "VirtualMachine": "VMware vSphere VM",
    "HostSystem": "VMware vSphere ESXi Host",
    "ClusterComputeResource": "VMware vSphere Cluster",
    "ResourcePool": "VMware vSphere Resource Pool",
    "Datacenter": "VMware vSphere Data Center",
    "Datastore": "VMware vSphere Data Store",
    "VApp": "VMware vSphere vApp",
    "Folder": "VMware vSphere vCenter"
}

MONITORED_EVENTS = {
    "vim.event.VmPoweredOnEvent",
    "vim.event.VmPoweredOffEvent",
    "vim.event.VmSuspendedEvent",
    "vim.event.VmCreatedEvent",
    "vim.event.VmRemovedEvent",
    "vim.event.VmMigratedEvent",
    "vim.event.VmBeingHotMigratedEvent",
    "vim.event.VmReconfiguredEvent",
    "vim.event.HostConnectedEvent",
    "vim.event.HostDisconnectedEvent",
    "vim.event.HostCrashedEvent",
    "vim.event.EnteredMaintenanceModeEvent",
    "vim.event.ExitedMaintenanceModeEvent",
    "vim.event.HostUpgradedEvent",
    "vim.event.DrsVmMigratedEvent",
    "vim.event.DasVmFailedEvent",
    "vim.event.DasVmRestartedEvent",
    "vim.event.ClusterReconfiguredEvent",
    "vim.event.DatastoreRemovedEvent",
    "vim.event.DatastoreFileDeletedEvent",
    "vim.event.StorageDrsRecommendationEvent",
}

# Event → Entity mapping (sample, expand as needed)
EVENT_ENTITY_MAP = {
    "vim.event.VmCreatedEvent": "Vmware_VM_INSTANCE",
    "vim.event.VmRemovedEvent": "Vmware_VM_INSTANCE",
    "vim.event.VmRelocatedEvent": "Vmware_VM_INSTANCE",
    "vim.event.VmMigratedEvent": "Vmware_VM_INSTANCE",
    "vim.event.VmRenamedEvent": "Vmware_VM_INSTANCE",
    "vim.event.VmReconfiguredEvent": "Vmware_VM_INSTANCE",
    "vim.event.VmRegisteredEvent": "Vmware_VM_INSTANCE",
    "vim.event.VmDestroyedEvent": "Vmware_VM_INSTANCE",
    "vim.event.HostAddedEvent": "Vmware_ESXI_HOST",
    "vim.event.HostRemovedEvent": "Vmware_ESXI_HOST",
    "vim.event.ClusterCreatedEvent": "Vmware_CLUSTER",
    "vim.event.ClusterDestroyedEvent": "Vmware_CLUSTER",
    "vim.event.DatastoreCreatedEvent": "Vmware_DATASTORE",
    "vim.event.DatastoreRemovedEvent": "Vmware_DATASTORE",
}

# Event → Entity type mapping
EVENT_ENTITY_TYPE_MAP = {
    # VM lifecycle
    "vim.event.VmCreatedEvent": "VMware vSphere VM",
    "vim.event.VmRemovedEvent": "VMware vSphere VM",
    "vim.event.VmMigratedEvent": "VMware vSphere VM",
    "vim.event.VmBeingHotMigratedEvent": "VMware vSphere VM",
    "vim.event.VmPoweredOnEvent": "VMware vSphere VM",
    "vim.event.VmPoweredOffEvent": "VMware vSphere VM",
    "vim.event.VmSuspendedEvent": "VMware vSphere VM",
    "vim.event.VmReconfiguredEvent": "VMware vSphere VM",

    # Host lifecycle
    "vim.event.HostConnectedEvent": "VMware vSphere ESXi Host",
    "vim.event.HostDisconnectedEvent": "VMware vSphere ESXi Host",
    "vim.event.HostCrashedEvent": "VMware vSphere ESXi Host",
    "vim.event.EnteredMaintenanceModeEvent": "VMware vSphere ESXi Host",
    "vim.event.ExitedMaintenanceModeEvent": "VMware vSphere ESXi Host",
    "vim.event.HostUpgradedEvent": "VMware vSphere ESXi Host",

    # HA/DRS/Cluster events
    "vim.event.DrsVmMigratedEvent": "VMware vSphere Cluster",
    "vim.event.DasVmFailedEvent": "VMware vSphere Cluster",
    "vim.event.DasVmRestartedEvent": "VMware vSphere Cluster",
    "vim.event.ClusterReconfiguredEvent": "VMware vSphere Cluster",

    # Datastore/storage events
    "vim.event.DatastoreRemovedEvent": "VMware vSphere Data Store",
    "vim.event.DatastoreFileDeletedEvent": "VMware vSphere Data Store",
    "vim.event.StorageDrsRecommendationEvent": "VMware vSphere Data Store",
}


SYNTHETIC_ALARM_LIBRARY = {
    "VirtualMachine": [
        ("CPU usage", ["green", "yellow", "red"]),
        ("Memory usage", ["green", "yellow", "red"]),
        ("Heartbeat", ["green", "yellow", "red"]),
        ("Disk latency", ["green", "yellow", "red"]),
    ],
    "HostSystem": [
        ("Connection State", ["green", "red"]),
        ("Hardware Sensor", ["green", "yellow", "red"]),
        ("CPU usage", ["green", "yellow", "red"]),
        ("Memory usage", ["green", "yellow", "red"]),
    ],
    "ClusterComputeResource": [
        ("DRS Imbalance", ["green", "yellow"]),
        ("HA Failover", ["green", "red"]),
    ],
    "Datastore": [
        ("Usage", ["green", "yellow", "red"]),
        ("Latency", ["green", "yellow", "red"]),
        ("Unmounted", ["green", "red"]),
    ],
    "ResourcePool": [
        ("CPU usage", ["green", "yellow", "red"]),
        ("Memory usage", ["green", "yellow", "red"]),
    ],
}
