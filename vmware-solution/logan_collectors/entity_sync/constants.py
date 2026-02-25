# constants.py

VMWARE_ENTITY_TYPES = {
    "VMware vSphere VM",
    "VMware vSphere ESXi Host",
    "VMware vSphere Cluster",
    "VMware vSphere Resource Pool",
    "VMware vSphere vCenter",
    "VMware vSphere Data Center",
#    "VMware vSphere vApp",
    "VMware vSphere Data Store"
}


INTERESTED_ENTITY_TYPES = {
    "VirtualMachine": "VMware vSphere VM",
    "HostSystem": "VMware vSphere ESXi Host",
    "ClusterComputeResource": "VMware vSphere Cluster",
    "ResourcePool": "VMware vSphere Resource Pool",
    "Datacenter": "VMware vSphere Data Center",
    "Datastore": "VMware vSphere Data Store",
#    "VApp": "VMware vSphere vApp",
    "Folder": "VMware vSphere vCenter"
}

OCI_RATE_LIMIT_CALLS = 100
OCI_RATE_LIMIT_PERIOD = 60
CACHE_TTL_SECONDS = 300

