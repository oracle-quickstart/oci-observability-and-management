import ssl
import logging


class VCenterClient:
    def __init__(self, host, user, password, dry_run=False):
        self.host = host
        self.user = user
        self.password = password
        self.dry_run = dry_run
        self.si = None
        self.content = None

    def connect(self):
        try:
            from pyVim.connect import SmartConnect
            context = ssl._create_unverified_context()
            self.si = SmartConnect(
                host=self.host,
                user=self.user,
                pwd=self.password,
                sslContext=context
            )
            self.content = self.si.RetrieveContent()
            logging.info("Connected to vCenter: %s", self.host)
        except Exception as e:
            logging.exception("Failed to connect to vCenter.")
            raise

    def disconnect(self):
        try:
            if self.si:
                from pyVim.connect import Disconnect
                Disconnect(self.si)
                logging.info("Disconnected from vCenter.")
        except Exception:
            logging.warning("Could not disconnect from vCenter cleanly.")

    def get_entities(self):
        """
        Fetch entities of interest from vCenter.
        Returns: list of dicts {name, type, parent}
        """
        try:
            from pyVmomi import vim

            if not self.content:
                raise RuntimeError("Not connected to vCenter.")

            results = []

            # vCenter root
            results.append({
                "name": self.host,
                "type": "VMware vSphere vCenter",
                "parent": None
            })

            for dc in self.content.rootFolder.childEntity:
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

            logging.info("Fetched %d entities from vCenter", len(results))
            return results

        except Exception as e:
            logging.exception("Failed to fetch entities from vCenter.")
            raise

