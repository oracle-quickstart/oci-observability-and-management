import random
import datetime
import logging
from typing import Dict, Any, List

logger = logging.getLogger("mock_vcenter")

# Mock collector that matches same shape as real collector
def collect_all_metrics_mock() -> Dict[str, List[Dict[str, Any]]]:
    now = utc_now_iso()
    return {
        "Vmware_CLUSTER": [
            {
                "name": "Cluster-1",
                "timestamp": now,
                "cpu_capacity_mhz": 20000,
                "cpu_used_mhz": 8000,
                "cpu_usage_percent": 40.0,
                "memory_capacity_mb": 262144,
                "memory_used_mb": 65536,
                "memory_usage_percent": 25.0,
                "num_hosts": 4,
                "num_vms": 120
            }
        ],
        "Vmware_DATASTORE": [
            {
                "name": "datastore01",
                "timestamp": now,
                "storage_capacity_tb": 20,
                "storage_used_tb": 10,
                "storage_free_tb": 10,
                "storage_usage_percent": 50.0,
                "accessible": True,
                "url": "ds:///vmfs/volumes/datastore01"
            }
        ],
        "Vmware_VM_INSTANCE": [
            {
                "name": "vm-01",
                "timestamp": now,
                "cpu_capacity_mhz": 2000,
                "cpu_used_mhz": 500,
                "cpu_usage_percent": 25.0,
                "memory_capacity_mb": 8192,
                "memory_used_mb": 2048,
                "memory_usage_percent": 25.0
            }
        ],
        "Vmware_ESXI_HOST": [
            {
                "name": "esxi-01",
                "timestamp": now,
                "cpu_capacity_mhz": 5000,
                "cpu_used_mhz": 2000,
                "cpu_usage_percent": 40.0,
                "memory_capacity_mb": 131072,
                "memory_used_mb": 32768,
                "memory_usage_percent": 25.0
            }
        ],
        "Vmware_NETWORK": [
            {
                "name": "VM Network",
                "timestamp": now,
                "num_connected_vms": 10
            }
        ],
        "VMware_DATA_CENTER": [
            {
                "name": "DC-1",
                "timestamp": now,
                "clusters_count": 2,
                "hosts_count": 8,
                "datastores_count": 4,
                "networks_count": 6,
                "vms_count": 240
            }
        ]
    }



class MockEvent:
    """A simple event object that looks like a pyVmomi event."""

    def __init__(self, event_type, vm=None, host=None, datastore=None,
                 cluster=None, dc=None, message=None, created_time=None):
        self.eventType = event_type
        self.fullFormattedMessage = message or f"{event_type} occurred"
        self.createdTime = created_time or datetime.datetime.utcnow()
        self.vm = vm
        self.host = host
        self.datastore = datastore
        self.cluster = cluster
        self.dc = dc


class MockVCenterClient:
    """
    A mock VCenterClient to simulate VMware lifecycle events
    for testing dry-run / mock modes.
    """

    def __init__(self, config):
        self.config = config
        self.entities = {
            "vm": ["vm-101", "vm-202", "vm-303"],
            "host": ["esxi-01", "esxi-02"],
            "datastore": ["datastore1", "datastore2"],
            "cluster": ["clusterA"],
            "dc": ["datacenter1"],
        }

    def fetch_events(self, since=None):
        """
        Return a random list of events that cover VM, Host, Datastore,
        Cluster lifecycle scenarios.
        """
        events = []
        now = datetime.datetime.utcnow()

        sample_events = [
            ("VmCreatedEvent", {"vm": "vm-101"}),
            ("VmRemovedEvent", {"vm": "vm-202"}),
            ("VmMigratedEvent", {"vm": "vm-303", "host": "esxi-01"}),
            ("VmBeingHotMigratedEvent", {"vm": "vm-101", "host": "esxi-02"}),
            ("VmPoweredOnEvent", {"vm": "vm-202"}),
            ("VmPoweredOffEvent", {"vm": "vm-202"}),
            ("VmSuspendedEvent", {"vm": "vm-101"}),
            ("VmReconfiguredEvent", {"vm": "vm-303"}),

            ("HostConnectedEvent", {"host": "esxi-01"}),
            ("HostDisconnectedEvent", {"host": "esxi-02"}),
            ("HostCrashedEvent", {"host": "esxi-02"}),
            ("EnteredMaintenanceModeEvent", {"host": "esxi-01"}),
            ("ExitedMaintenanceModeEvent", {"host": "esxi-01"}),
            ("HostUpgradedEvent", {"host": "esxi-02"}),

            ("DrsVmMigratedEvent", {"cluster": "clusterA", "vm": "vm-101"}),
            ("DasVmFailedEvent", {"cluster": "clusterA", "vm": "vm-202"}),
            ("DasVmRestartedEvent", {"cluster": "clusterA", "vm": "vm-202"}),
            ("ClusterReconfiguredEvent", {"cluster": "clusterA"}),

            ("DatastoreRemovedEvent", {"datastore": "datastore1"}),
            ("DatastoreFileDeletedEvent", {"datastore": "datastore2"}),
            ("StorageDrsRecommendationEvent", {"datastore": "datastore2"}),
        ]

        # Randomly pick 3–6 events for variety
        for event_type, attrs in random.sample(sample_events, k=random.randint(3, 6)):
            e = MockEvent(
                event_type,
                vm=attrs.get("vm"),
                host=attrs.get("host"),
                datastore=attrs.get("datastore"),
                cluster=attrs.get("cluster"),
                dc=attrs.get("dc", "datacenter1"),
                message=f"[MOCK] {event_type} simulated at {now.isoformat()}",
                created_time=now
            )
            events.append(e)

        logger.debug(f"Generated {len(events)} mock events")
        return events


