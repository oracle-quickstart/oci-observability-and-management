#!/usr/bin/env bash

set -e

data=$1
# Edit BASE_DIR
BASE_DIR="/home/opc/logan_collectors"
PYTHON_BIN="/usr/bin/python3"

# Optional: activate venv if you ship one
if [ -d "$BASE_DIR/venv" ]; then
    source "$BASE_DIR/venv/bin/activate"
    PYTHON_BIN="$BASE_DIR/venv/bin/python"
fi

if [ "$data" = "metrics" ]; then
    SCRIPT="$BASE_DIR/vmware_collector/collect_metrics.py"
    OUT_FILE="metric_collector.out"
elif [ "$data" = "events" ]; then
    SCRIPT="$BASE_DIR/vmware_collector/collect_events.py"
    OUT_FILE="event_collector.out"
elif [ "$data" = "alarms" ]; then
    SCRIPT="$BASE_DIR/vmware_collector/collect_alarms.py"
    OUT_FILE="alarm_collector.out"
elif [ "$data" = "entity_sync" ]; then
    SCRIPT="$BASE_DIR/entity_sync/entity_sync.py"
    OUT_FILE="entity_synchronizer.out"
elif [ "$data" = "init_entities" ]; then
    SCRIPT="$BASE_DIR/entity_discovery/main.py"
    exec "$PYTHON_BIN" "$SCRIPT" --base-dir $BASE_DIR 
    exit 0
else
    echo "This option is not supported"
    exit 1
fi

exec "$PYTHON_BIN" "$SCRIPT" --base-dir $BASE_DIR >> $BASE_DIR/logs/$OUT_FILE 2>&1

