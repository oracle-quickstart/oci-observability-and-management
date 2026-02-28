#
# Copyright (c) 2026 Oracle, Inc.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#
# synthetic_alarms.py
import random
from datetime import datetime, timedelta, timezone
import logging
from constants import INTERESTED_ENTITY_TYPES, SYNTHETIC_ALARM_LIBRARY

logging.basicConfig(level=logging.INFO, format='%(asctime)s [%(levelname)s] %(message)s')


def normalize_la_type(s):
    """
    Normalize LA entity type for robust matching:
      - strip whitespace
      - lowercase
      - collapse multiple spaces
    """
    return " ".join(s.strip().lower().split())


class SyntheticVCenterAlarm:
    """
    Wrap a synthetic alarm as a vCenter-like object compatible with build_log_events().
    """
    def __init__(self, entity_name, la_type, entity_id, alarm_name,
                 status_from, status_to, created_time, event_key):
        # Mimic entity object
        self.entity = type("Entity", (), {})()
        self.entity.entity = f"vim.{la_type}:{entity_name}"
        self.entity.name = entity_name

        # Mimic alarm object
        self.alarm = type("Alarm", (), {})()
        self.alarm.name = alarm_name

        # Critical top-level attributes so build_log_events() works
        setattr(self, "from", status_from)  # top-level 'from'
        setattr(self, "to", status_to)      # top-level 'to'
        setattr(self, "key", event_key)     # top-level 'key'

        # Also set named attributes for clarity
        self.statusFrom = status_from
        self.statusTo = status_to
        self.eventKey = event_key
        self.alarmName = alarm_name
        self.alarmInstanceKey = f"{self.entity.entity}-{alarm_name}"

        # Other top-level attributes
        self.createdTime = created_time
        self.fullFormattedMessage = f"Alarm '{alarm_name}' on {entity_name} changed from {status_from} to {status_to}"
        self.userName = "system"

        # Set eventType exactly as in vCenter alarms
        self.eventType = "vim.event.AlarmStatusChangedEvent"


def generate_synthetic_alarms_for_cache(entity_cache, count=3, base_time=None):
    """
    Generate synthetic alarms for VMware-related entities in the entity cache.

    Args:
        entity_cache (dict): key = tuple (normalized LA entity type, entity name)
                             value = entity OCID
        count (int): number of synthetic alarms per entity
        base_time (datetime, optional): reference timestamp for alarms

    Returns:
        list of SyntheticVCenterAlarm objects
    """
    now = base_time or datetime.now(timezone.utc)
    synthetic = []

    logging.info("Checking entity cache types against INTERESTED_ENTITY_TYPES")
    total_entities = len(entity_cache)
    if total_entities == 0:
        logging.warning("No entities found in cache.")
        return synthetic

    logging.info(f"Total entities in cache: {len(entity_cache)}")
    # Build normalized mapping: lowercase LA type -> VMware type
    la_to_vmware = {normalize_la_type(v): k for k, v in INTERESTED_ENTITY_TYPES.items()}
    allowed_la_types = set(la_to_vmware.keys())

    # Choose 5 random entity indices
    selected_indices = set(random.sample(range(total_entities), min(5, total_entities)))
    logging.info(f"Selected entity indices for synthetic alarms: {sorted(selected_indices)}")

    total_generated = 0
    idx = 0
    for key, entity_id in entity_cache.items():
        idx = idx+1
        #Only generate alarms for selected entities
        if idx not in selected_indices:
            continue

        # Handle tuple keys (la_type, entity_name)
        if isinstance(key, tuple) and len(key) == 2:
            la_type_raw, entity_name = key
        else:
            logging.warning(f"Skipping invalid cache key: {key}")
            continue

        la_type_norm = normalize_la_type(la_type_raw)
        logging.debug(f"Processing entity: LA Type='{la_type_norm}', Name='{entity_name}'")

        if la_type_norm not in allowed_la_types:
            logging.debug(f"Skipped entity (not in INTERESTED_ENTITY_TYPES): {la_type_raw}:{entity_name}")
            continue

        # Lookup VMware type
        vmware_type = la_to_vmware.get(la_type_norm)
        if not vmware_type:
            logging.warning(f"No VMware type mapping for LA type '{la_type_raw}'")
            continue

        alarm_defs = SYNTHETIC_ALARM_LIBRARY.get(vmware_type, [])
        if not alarm_defs:
            logging.debug(f"No synthetic alarm definitions for VMware type: {vmware_type}")
            continue

        logging.info(f"Generating {count} synthetic alarms for entity '{entity_name}' of type '{vmware_type}'")

        for i in range(count):
            alarm_name, states = random.choice(alarm_defs)
            if len(states) < 2:
                continue
            status_from, status_to = random.sample(states, 2)
            event_time = now + timedelta(seconds=i * 10)
            event_key = random.randint(100000, 999999)

            # Create a vCenter-like synthetic alarm
            synthetic_alarm = SyntheticVCenterAlarm(
                entity_name=entity_name,
                la_type=vmware_type,
                entity_id=entity_id,
                alarm_name=alarm_name,
                status_from=status_from,
                status_to=status_to,
                created_time=event_time,
                event_key=event_key
            )
            synthetic.append(synthetic_alarm)
            total_generated += 1

    logging.info(f"Total synthetic alarms generated: {total_generated}")
    if total_generated == 0:
        logging.warning("No synthetic alarms were generated. Check entity cache and INTERESTED_ENTITY_TYPES mapping.")

    return synthetic

