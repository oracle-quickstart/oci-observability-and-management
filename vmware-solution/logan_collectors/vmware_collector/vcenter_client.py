# vcenter_client.py
"""
Robust vCenter metrics collector.

Returns a dict keyed by internal entity type names expected by main.py:
  - "Vmware_CLUSTER"
  - "Vmware_DATASTORE"
  - "Vmware_VM_INSTANCE"
  - "Vmware_ESXI_HOST"
  - "Vmware_NETWORK"
  - "VMware_DATA_CENTER"

Each value is a list of dicts:
  { "name": <str>, "timestamp": <iso str>, <metric_kv_pairs>... }

This module uses vSphere summary / quickStats where possible and falls back to aggregation
to avoid null/perfmanager issues. It logs missing attributes and exceptions.
"""

import ssl
import atexit
import logging
from datetime import datetime, timezone
from typing import Dict, Any, List

from pyVim.connect import SmartConnect, Disconnect
from pyVmomi import vim
from constants import MONITORED_EVENTS

logger = logging.getLogger("vcenter_client")
logger.setLevel(logging.DEBUG)

#
# -------- Helpers --------
#
def normalize_entity_type(entity_type: str) -> str:
    if not entity_type:
        return ""
    return entity_type.strip().strip("'").strip('"')


def parse_iso_datetime(s):
    """
    Parse an ISO 8601 datetime string into a UTC-aware datetime.
    Compatible with Python 3.6.
    """
    if s is None:
        return None
    if isinstance(s, datetime):
        dt = s
    else:
        s = s.strip()
        dt = None

        # Handle trailing Z (Zulu = UTC)
        if s.endswith("Z"):
            try:
                dt = datetime.strptime(s, "%Y-%m-%dT%H:%M:%S.%fZ")
            except ValueError:
                try:
                    dt = datetime.strptime(s, "%Y-%m-%dT%H:%M:%SZ")
                except ValueError:
                    pass
            if dt:
                dt = dt.replace(tzinfo=timezone.utc)

        # Handle timezone with colon (+00:00)
        if dt is None:
            # Rewrite "+HH:MM" → "+HHMM"
            s2 = re.sub(r'([+-]\d{2}):(\d{2})$', r'\1\2', s)
            for fmt in ("%Y-%m-%dT%H:%M:%S.%f%z",
                        "%Y-%m-%dT%H:%M:%S%z"):
                try:
                    dt = datetime.strptime(s2, fmt)
                    break
                except ValueError:
                    continue

        # Fallback: naive datetime (no timezone)
        if dt is None:
            for fmt in ("%Y-%m-%dT%H:%M:%S.%f",
                        "%Y-%m-%dT%H:%M:%S"):
                try:
                    dt = datetime.strptime(s, fmt)
                    break
                except ValueError:
                    continue

    if dt is None:
        raise ValueError(f"Unrecognized date format: {s}")

    # Ensure tz-aware UTC
    if dt.tzinfo is None:
        dt = dt.replace(tzinfo=timezone.utc)
    else:
        dt = dt.astimezone(timezone.utc)

    return dt

def utc_now_iso() -> str:
    return datetime.utcnow().replace(tzinfo=timezone.utc).isoformat()

def safe_get(obj, attr: str, default=None):
    """Safe getattr wrapper using dotted attribute path (a.b.c)."""
    try:
        parts = attr.split(".")
        cur = obj
        for p in parts:
            if cur is None:
                return default
            cur = getattr(cur, p, None)
        return cur if cur is not None else default
    except Exception:
        return default

def safe_div(a, b):
    try:
        return a / b if b else None
    except Exception:
        return None

def normalize_name(n):
    return n.strip() if isinstance(n, str) else (str(n) if n is not None else "")

def get_short_event_type(t):
  """
  Returns all content after the final '.' character in a string.
  If no '.' is present, the entire original string is returned.
  """
  # Split the string into a list of components using the dot as a separator
  parts = t.split('.')

  # Return the last element of that list
  return parts[-1]

#
# Class
#
class VCenterClient:
    def __init__(self, host, port, user, password):
        self.host = host
        self.port = port
        self.user = user
        self.password = password
        self.si = None
    #    self.content = None
    #
    # -------- vCenter Connection --------
    #
    def connect(self,  allow_unverified=True):
        """
        Connect to vCenter using pyVmomi.
        If allow_unverified=True, disables SSL verification.
        """
        context = None
        if allow_unverified and hasattr(ssl, "_create_unverified_context"):
            context = ssl._create_unverified_context()
    
        try:
            si = SmartConnect(host=self.host, user=self.user, pwd=self.password, sslContext=context)
            atexit.register(Disconnect, si)
            logger.info(f"Connected to vCenter: {self.host}")
            return si
        except Exception as e:
            raise RuntimeError(f"Failed to connect to vCenter {self.host}: {e}")


    def get_entities(self):
        """
        Fetch entities of interest from vCenter.
        Returns: list of dicts {name, type, parent}
        """
        try:

            si = self.connect()
    
            content = si.RetrieveContent()

            if not content:
                raise RuntimeError("Not connected to vCenter.")

            results = []

            # vCenter root
            results.append({
                "name": self.host,
                "type": "VMware vSphere vCenter",
                "parent": None
            })

            for dc in content.rootFolder.childEntity:
                if isinstance(dc, vim.Datacenter):
                    results.append({
                        "name": dc.name,
                        "type": "VMware vSphere Data Center",
                        "parent": {"type": "VMware vSphere vCenter", "name": self.host}
                    })

                    # Clusters & hosts
                    for cluster in dc.hostFolder.childEntity:
                        if isinstance(cluster, vim.ClusterComputeResource):
                            results.append({
                                "name": cluster.name,
                                "type": "VMware vSphere Cluster",
                                "parent": {"type": "VMware vSphere Data Center", "name": dc.name}
                            })

                            for host in cluster.host:
                                results.append({
                                    "name": host.name,
                                    "type": "VMware vSphere ESXi Host",
                                    "parent": {"type": "VMware vSphere Cluster", "name": cluster.name}
                                })

                                for vm in host.vm:
                                    results.append({
                                        "name": vm.name,
                                        "type": "VMware vSphere VM",
                                        "parent": {"type": "VMware vSphere ESXi Host", "name": host.name}
                                    })

                        elif isinstance(cluster, vim.ComputeResource):
                            for host in cluster.host:
                                results.append({
                                    "name": host.name,
                                    "type": "VMware vSphere ESXi Host",
                                    "parent": {"type": "VMware vSphere Data Center", "name": dc.name}
                                })
                                for vm in host.vm:
                                    results.append({
                                        "name": vm.name,
                                        "type": "VMware vSphere VM",
                                        "parent": {"type": "VMware vSphere ESXi Host", "name": host.name}
                                    })

                    # Datastores
                    for ds in dc.datastore:
                        results.append({
                            "name": ds.name,
                            "type": "VMware vSphere Data Store",
                            "parent": {"type": "VMware vSphere Data Center", "name": dc.name}
                        })

                    # vApps
                    for vm in dc.vmFolder.childEntity:
                        if isinstance(vm, vim.VirtualApp):
                            results.append({
                                "name": vm.name,
                                "type": "VMware vSphere vApp",
                                "parent": {"type": "VMware vSphere Data Center", "name": dc.name}
                            })
#                    for net in getattr(dc, "network", []):
#                        results.append({
#                            "type": "VMware vSphere Network",
#                            "name": net.name,
#                            "parent": {
#                                "type": "VMware vSphere Data Center", "name": dc.name
#                            }
#                        })

            logger.info("Fetched %d entities from vCenter", len(results))
            return results

        except Exception as e:
            logger.exception("Failed to fetch entities from vCenter.")
            raise

    
    # 
    # Collect Metrics
    #
    #def collect_metrics(self) -> Dict[str, List[Dict[str, Any]]]:
    def collect_metrics(self):
        """
        Collect metrics from a real vCenter instance.
        """
    
        si = self.connect()
    
        content = si.RetrieveContent()
    
        now = utc_now_iso()
    
        # prepare containers
        collected: Dict[str, List[Dict[str, Any]]] = {
            "Vmware_CLUSTER": [],
            "Vmware_DATASTORE": [],
            "Vmware_VM_INSTANCE": [],
            "Vmware_ESXI_HOST": [],
    #        "Vmware_NETWORK": [],
            "VMware_DATA_CENTER": []
        }
    
        # Create views (efficient)
        vm_view = content.viewManager.CreateContainerView(content.rootFolder, [vim.VirtualMachine], True)
        host_view = content.viewManager.CreateContainerView(content.rootFolder, [vim.HostSystem], True)
        ds_view = content.viewManager.CreateContainerView(content.rootFolder, [vim.Datastore], True)
    #    net_view = content.viewManager.CreateContainerView(content.rootFolder, [vim.Network], True)
        cluster_view = content.viewManager.CreateContainerView(content.rootFolder, [vim.ClusterComputeResource], True)
        dc_view = content.viewManager.CreateContainerView(content.rootFolder, [vim.Datacenter], True)
    
        # -------------------------
        # Hosts (ESXi)
        # -------------------------
        host_stats_cache = {}  # name -> metrics (used by cluster aggregation)
        for host in host_view.view:
            try:
                name = normalize_name(getattr(host, "name", ""))
                qs = safe_get(host, "summary.quickStats", None)
                hw = safe_get(host, "hardware", None)
    
                # CPU capacity: construct from hw if available (hz * numCpuCores) -> Hz -> MHz
                cpu_capacity_mhz = None
                try:
                    if hw and getattr(hw, "cpuInfo", None):
                        hz = safe_get(hw, "cpuInfo.hz", None)
                        cores = safe_get(hw, "cpuInfo.numCpuCores", None)
                        if hz and cores:
                            cpu_capacity_mhz = (hz * cores) / 1e6  # to MHz
                except Exception:
                    cpu_capacity_mhz = None
    
                cpu_used_mhz = safe_get(qs, "overallCpuUsage", None)  # already in MHz
                mem_capacity_mb = None
                try:
                    if hw and getattr(hw, "memorySize", None) is not None:
                        mem_capacity_mb = hw.memorySize / (1024 * 1024)
                except Exception:
                    mem_capacity_mb = None
    
                mem_used_mb = safe_get(qs, "overallMemoryUsage", None)  # MB
    
                # compute percentages if possible
                cpu_usage_pct = round(safe_div(cpu_used_mhz, cpu_capacity_mhz) * 100, 2) if cpu_capacity_mhz and cpu_used_mhz is not None else None
                mem_usage_pct = round(safe_div(mem_used_mb, mem_capacity_mb) * 100, 2) if mem_capacity_mb and mem_used_mb is not None else None
    
                host_metrics = {
                    "name": name,
                    "timestamp": now,
                    "cpu_capacity_mhz": round(cpu_capacity_mhz, 2) if cpu_capacity_mhz is not None else None,
                    "cpu_used_mhz": cpu_used_mhz if cpu_used_mhz is not None else None,
                    "cpu_usage_percent": cpu_usage_pct,
                    "memory_capacity_mb": round(mem_capacity_mb, 2) if mem_capacity_mb is not None else None,
                    "memory_used_mb": mem_used_mb if mem_used_mb is not None else None,
                    "memory_usage_percent": mem_usage_pct
                }
                collected["Vmware_ESXI_HOST"].append(host_metrics)
                host_stats_cache[name] = host_metrics
            except Exception as e:
                log.exception(f"Error collecting host metrics for host object: {e}")
    
        # -------------------------
        # VMs
        # -------------------------
        vm_stats_cache = {}
        for vm in vm_view.view:
            try:
                name = normalize_name(getattr(vm, "name", ""))
                qs = safe_get(vm, "summary.quickStats", None)
                summary = safe_get(vm, "summary", None)
    
                # CPU: quickStats.overallCpuUsage is in MHz (host CPU MHz consumed)
                cpu_used_mhz = safe_get(qs, "overallCpuUsage", None)
                # CPU capacity: runtime.maxCpuUsage (MHz) sometimes available in summary.runtime.maxCpuUsage; fallback to config.numCpu * host hz unknown
                cpu_capacity_mhz = safe_get(summary, "runtime.maxCpuUsage", None)
                if cpu_capacity_mhz is None:
                    # fallback: if we can get config.numCpu and the host CPU hz from VM.runtime.host? expensive - skip
                    cpu_capacity_mhz = None
    
                cpu_usage_pct = round(safe_div(cpu_used_mhz, cpu_capacity_mhz) * 100, 2) if cpu_capacity_mhz and cpu_used_mhz is not None else None
    
                # Memory: hostMemoryUsage (MB) and config.memorySizeMB (MB)
                mem_used_mb = safe_get(qs, "hostMemoryUsage", None) or safe_get(qs, "guestMemoryUsage", None)
                mem_capacity_mb = safe_get(summary, "config.memorySizeMB", None)
                mem_usage_pct = round(safe_div(mem_used_mb, mem_capacity_mb) * 100, 2) if mem_capacity_mb and mem_used_mb is not None else None
    
                vm_metrics = {
                    "name": name,
                    "timestamp": now,
                    "cpu_capacity_mhz": cpu_capacity_mhz if cpu_capacity_mhz is not None else None,
                    "cpu_used_mhz": cpu_used_mhz if cpu_used_mhz is not None else None,
                    "cpu_usage_percent": cpu_usage_pct,
                    "memory_capacity_mb": mem_capacity_mb if mem_capacity_mb is not None else None,
                    "memory_used_mb": mem_used_mb if mem_used_mb is not None else None,
                    "memory_usage_percent": mem_usage_pct
                }
                collected["Vmware_VM_INSTANCE"].append(vm_metrics)
                vm_stats_cache[name] = vm_metrics
            except Exception as e:
                log.exception(f"Error collecting VM metrics for VM: {e}")
    
        # -------------------------
        # Datastores
        # -------------------------
        for ds in ds_view.view:
            try:
                summary = safe_get(ds, "summary", {})
                ds_name = normalize_name(safe_get(summary, "name", safe_get(ds, "name", "")))
                capacity_bytes = safe_get(summary, "capacity", None)
                free_bytes = safe_get(summary, "freeSpace", None)
                if capacity_bytes is not None and free_bytes is not None:
                    capacity_tb = capacity_bytes / (1024 ** 4)
                    free_tb = free_bytes / (1024 ** 4)
                    used_tb = capacity_tb - free_tb
                    usage_pct = round(safe_div(used_tb, capacity_tb) * 100, 2) if capacity_tb else None
                else:
                    capacity_tb = free_tb = used_tb = usage_pct = None
    
                ds_metrics = {
                    "name": ds_name,
                    "timestamp": now,
                    "storage_capacity_tb": round(capacity_tb, 2) if capacity_tb is not None else None,
                    "storage_used_tb": round(used_tb, 2) if used_tb is not None else None,
                    "storage_free_tb": round(free_tb, 2) if free_tb is not None else None,
                    "storage_usage_percent": usage_pct,
                    "accessible": safe_get(summary, "accessible", None),
                    "url": safe_get(summary, "url", "")
                }
                collected["Vmware_DATASTORE"].append(ds_metrics)
            except Exception as e:
                log.exception(f"Error collecting datastore metrics: {e}")
    
        # -------------------------
        # Networks
        # -------------------------
        # For networks, not all types expose .vm; count connected powered-on VMs by checking vm.network membership
        # Build VM -> network membership map to avoid repeated scans
    #    try:
    #        vm_networks_map = {}
    #        for vm in vm_view.view:
    #            vm_name = normalize_name(getattr(vm, "name", ""))
    #            vm_networks = getattr(vm, "network", []) or []
    #            # convert to names or object references — use object identity for matching below
    #            vm_networks_map[vm] = set(vm_networks)
    #    except Exception:
    #        vm_networks_map = {}
    #
    #    for net in net_view.view:
    #        try:
    #            net_name = normalize_name(getattr(net, "name", ""))
    #            # count VMs that reference this network object in their network list and are poweredOn
    #            num_connected = 0
    #            for vm in vm_view.view:
    #                try:
    #                    if vm.runtime and vm.runtime.powerState != "poweredOn":
    #                        continue
    #                    vm_networks = getattr(vm, "network", []) or []
    #                    # vm_networks may be list of network objects; compare objects
    #                    if net in vm_networks:
    #                        num_connected += 1
    #                except Exception:
    #                    continue
    #            net_metrics = {
    #                "name": net_name,
    #                "timestamp": now,
    #                "num_connected_vms": num_connected
    #            }
    #            collected["Vmware_NETWORK"].append(net_metrics)
    #        except Exception as e:
    #            log.exception(f"Error collecting network metrics for {getattr(net, 'name', None)}: {e}")
    
        # -------------------------
        # Clusters (aggregate fallback)
        # -------------------------
        for cluster in cluster_view.view:
            try:
                name = normalize_name(getattr(cluster, "name", ""))
                # prefer cluster.summary where available
                summary = safe_get(cluster, "summary", None)
                cpu_capacity_mhz = safe_get(summary, "totalCpu", None)  # totalCpu is MHz
                mem_capacity_bytes = safe_get(summary, "totalMemory", None)
                mem_capacity_mb = mem_capacity_bytes / (1024 * 1024) if mem_capacity_bytes is not None else None
    
                cpu_used_mhz = None
                mem_used_mb = None
    
                # try usageSummary on summary (may not exist)
                usage_summary = safe_get(summary, "usageSummary", None)
                if usage_summary:
                    cpu_used_mhz = safe_get(usage_summary, "cpuUsedMhz", None)
                    mem_used_mb = safe_get(usage_summary, "memUsedMB", None)
    
                # fallback: aggregate host metrics for this cluster
                if cpu_used_mhz is None or mem_used_mb is None:
                    # get hosts in this cluster
                    hosts = getattr(cluster, "host", []) or []
                    agg_cpu_used = 0.0
                    agg_cpu_capacity = 0.0
                    agg_mem_used = 0.0
                    agg_mem_capacity = 0.0
                    host_count = 0
                    for h in hosts:
                        hname = normalize_name(getattr(h, "name", ""))
                        host_data = host_stats_cache.get(hname)
                        if host_data:
                            host_count += 1
                            if host_data.get("cpu_used_mhz") is not None:
                                agg_cpu_used += host_data.get("cpu_used_mhz", 0)
                            if host_data.get("cpu_capacity_mhz") is not None:
                                agg_cpu_capacity += host_data.get("cpu_capacity_mhz", 0)
                            if host_data.get("memory_used_mb") is not None:
                                agg_mem_used += host_data.get("memory_used_mb", 0)
                            if host_data.get("memory_capacity_mb") is not None:
                                agg_mem_capacity += host_data.get("memory_capacity_mb", 0)
    
                    if host_count:
                        # use aggregated values where available
                        cpu_used_mhz = cpu_used_mhz if cpu_used_mhz is not None else (agg_cpu_used if agg_cpu_used else None)
                        cpu_capacity_mhz = cpu_capacity_mhz if cpu_capacity_mhz is not None else (agg_cpu_capacity if agg_cpu_capacity else None)
                        mem_used_mb = mem_used_mb if mem_used_mb is not None else (agg_mem_used if agg_mem_used else None)
                        mem_capacity_mb = mem_capacity_mb if mem_capacity_mb is not None else (agg_mem_capacity if agg_mem_capacity else None)
                    else:
                        # if no hosts, keep whatever summary provided or None
                        pass
    
                # compute percents
                cpu_usage_pct = round(safe_div(cpu_used_mhz, cpu_capacity_mhz) * 100, 2) if cpu_used_mhz is not None and cpu_capacity_mhz else None
                mem_usage_pct = round(safe_div(mem_used_mb, mem_capacity_mb) * 100, 2) if mem_used_mb is not None and mem_capacity_mb else None
    
                cluster_metrics = {
                    "name": name,
                    "timestamp": now,
                    "cpu_capacity_mhz": round(cpu_capacity_mhz, 2) if cpu_capacity_mhz is not None else None,
                    "cpu_used_mhz": cpu_used_mhz if cpu_used_mhz is not None else None,
                    "cpu_usage_percent": cpu_usage_pct,
                    "memory_capacity_mb": round(mem_capacity_mb, 2) if mem_capacity_mb is not None else None,
                    "memory_used_mb": mem_used_mb if mem_used_mb is not None else None,
                    "memory_usage_percent": mem_usage_pct,
                    "num_hosts": len(getattr(cluster, "host", []) or []),
                    "num_vms": sum(len(getattr(h, "vm", []) or []) for h in getattr(cluster, "host", []) or [])
                }
                collected["Vmware_CLUSTER"].append(cluster_metrics)
            except Exception as e:
                log.exception(f"Error collecting cluster metrics for {getattr(cluster, 'name', None)}: {e}")
    
        # -------------------------
        # Data centers (counts)
        # -------------------------
        for dc in dc_view.view:
            try:
                name = normalize_name(getattr(dc, "name", ""))
                clusters_count = len(getattr(dc.hostFolder, "childEntity", []) or [])
                hosts_count = sum(len(getattr(c, "host", []) or []) for c in getattr(dc.hostFolder, "childEntity", []) or [])
                datastores_count = len(getattr(dc, "datastore", []) or [])
                networks_count = len(getattr(dc, "network", []) or [])
                # number of vms in datacenter via VM folder view
                vm_count = len(content.viewManager.CreateContainerView(dc, [vim.VirtualMachine], True).view)
                dc_metrics = {
                    "name": name,
                    "timestamp": now,
                    "clusters_count": clusters_count,
                    "hosts_count": hosts_count,
                    "datastores_count": datastores_count,
                    "networks_count": networks_count,
                    "vms_count": vm_count
                }
                collected["VMware_DATA_CENTER"].append(dc_metrics)
            except Exception as e:
                log.exception(f"Error collecting datacenter metrics for {getattr(dc, 'name', None)}: {e}")
    
        # cleanup views
        try:
            vm_view.Destroy()
        except Exception:
            pass
        try:
            host_view.Destroy()
        except Exception:
            pass
        try:
            ds_view.Destroy()
        except Exception:
            pass
    #    try:
    #        net_view.Destroy()
    #    except Exception:
    #        pass
        try:
            cluster_view.Destroy()
        except Exception:
            pass
        try:
            dc_view.Destroy()
        except Exception:
            pass
    
        return collected
    
    
        #
        # -------- Alarm Collection --------
        #
        
    def fetch_alarms(self, start_time=None, checkpoint_event_key=None, max_events=5000):
        """
        Fetch alarms (from EventManager) for entities of interest.
    
        Args:
            vcenter_cfg (dict): {host, user, password, allow_unverified_ssl?}
            interested_types (dict): mapping of vSphere type -> OCI LA type
            start_time (str|None): ISO timestamp string (from checkpoint)
            max_events (int): maximum number of alarm events to fetch
    
        Returns:
            List of alarms dicts:
            {
                "time": ISO8601 string,
                "entity_type": str,
                "entity_name": str,
                "alarm_name": str,
                "status": str
            }
        """
        si = self.connect()
        content = si.RetrieveContent()
        event_manager = content.eventManager
    
        # Convert checkpoint time
        start_dt = None
        if start_time:
            try:
                start_dt = parse_iso_datetime(start_time)
            except Exception:
                logger.warning(f"Invalid checkpoint time format: {start_time}")
                start_dt = None
    
        alarms_data = []
    
        # Build filter for Alarm* events
        filter_spec = vim.event.EventFilterSpec()
        if start_dt:
            time_filter = vim.event.EventFilterSpec.ByTime()
            time_filter.beginTime = start_dt
            filter_spec.time = time_filter
    
        # Only interested in alarm events
        event_collector = event_manager.CreateCollectorForEvents(filter_spec)
    
        try:
            fetched = 0
            batch_size = 200  # fetch events in smaller batches
            while fetched < max_events:
                events = event_collector.ReadNextEvents(batch_size)
                if not events:
                    break
    
                for event in events:
                    #logger.info(f"got alarm event: {event}")
                    if isinstance(event, (vim.event.AlarmCreatedEvent,
                                          vim.event.AlarmRemovedEvent,
                                          vim.event.AlarmStatusChangedEvent)):
                        try:
                            entity = getattr(event, "entity", None)
                            if not entity:
                                logger.info(f"Error getting entity from alarm event: {event}")
                                continue
    
                            if start_time and event.createdTime == start_dt:
                                if checkpoint_event_key is not None and getattr(event, "key", 0) <= checkpoint_event_key:
                                    continue
                            #logger.info(f"Raw entity object: {event.entity}")
                            #logger.info(f"Entity dir: {dir(event.entity)}")
                            #if hasattr(event.entity, "entity"):
                            #    logger.info(f"event.entity.entity: {event.entity.entity}, type: {type(event.entity.entity)}")
                            #if hasattr(event.entity.entity, "_type"):
                            #    logger.info(f"event.entity.entity._type = {event.entity.entity._type}")
                            #if hasattr(event.entity, "entityType"):
                            #    logger.info(f"event.entity.entityType = {event.entity.entityType}")
                            #if hasattr(event.entity, "name"):
                            #    logger.info(f"event.entity.name = {event.entity.name}")
    
                            #entity_ref = str(event.entity.entity)  # e.g. "'vim.VirtualMachine:vm-23'"
                            #if ":" in entity_ref:
                            #    entity_type_raw, entity_id = entity_ref.split(":", 1)
                            #    entity_type = normalize_entity_type(entity_type_raw.replace("vim.", ""))
                            #else:
                            #    entity_type = "unknown"
    #
    #                        entity_name = getattr(entity, "name", "unknown")
    #                        # Try extracting real type from ManagedObjectReference
    #                        if hasattr(entity, "entity") and hasattr(entity.entity, "_type"):
    #                            entity_type = entity.entity._type
    #
    #                        if entity_type not in interested_types:
    #                            continue
    #
    #                        alarm_name = getattr(event, "alarm", None)
    #                        if hasattr(alarm_name, "info"):
    #                            alarm_name = alarm_name.info.name
    #                        elif hasattr(alarm_name, "name"):
    #                            alarm_name = alarm_name.name
    #                        else:
    #                            alarm_name = "UnknownAlarm"
    #
    #                        status = getattr(event, "to", None) or "active"
    #                        event_time = getattr(event, "createdTime", datetime.utcnow())
    #
    #                        alarms_data.append({
    #                            "time": event_time.isoformat(),
    #                            "entity_type": entity_type,
    #                            "entity_name": entity_name,
    #                            "alarm_name": alarm_name,
    #                            "status": str(status)
    #                        })
                            alarms_data.append(event)
    
                            fetched += 1
                            if fetched >= max_events:
                                break
                        except Exception as e:
                            logger.error(f"Error processing alarm event: {e}")
    
                if fetched >= max_events:
                    break
    
        finally:
            event_collector.DestroyCollector()
    
        logger.info(f"Fetched {len(alarms_data)} alarms from vCenter (limit={max_events}).")
        return alarms_data


    def fetch_events(self, since_time=None, batch_size=1000):
        """
        Fetch up to batch_size monitored events from vCenter.
        Stops once we have batch_size filtered events or no more events.
        """
        try:
            si = self.connect()
            event_manager = si.content.eventManager
            filter_spec = self._build_filter(since_time)

            collector = event_manager.CreateCollectorForEvents(filter_spec)
            collector.SetCollectorPageSize(batch_size)

            filtered_events = []
            while len(filtered_events) < batch_size:
                batch = collector.ReadNextEvents(batch_size)
                if not batch:
                    break

                for event in batch:
                    event_type = getattr(event, "type", None) or event.__class__.__name__
                    #logger.info(f"Fetched event of type %s from vCenter", event_type)
                    if event_type in MONITORED_EVENTS:
                        filtered_events.append(event)
                        if len(filtered_events) >= batch_size:
                            break

            collector.DestroyCollector()
            logger.info(f"Fetched {len(filtered_events)} monitored events from vCenter")
            return filtered_events

        except Exception as e:
            logger.exception(f"Failed to fetch events: {e}")
            return []

    def _build_filter(self, since_time):
        from pyVmomi import vim
        filter_spec = vim.event.EventFilterSpec()
        if since_time:
            time_filter = vim.event.EventFilterSpec.ByTime(beginTime=since_time)
            filter_spec.time = time_filter
        return filter_spec
