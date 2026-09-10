#!/usr/bin/env bash
# Copyright (c) 2026 Oracle, Inc.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

set -Eeuo pipefail

usage() {
    cat <<'EOF'
Usage: bin/run.sh <operation>

Operations:
  metrics         Collect and upload vCenter metrics.
  events          Collect and upload vCenter events.
  alarms          Collect and upload vCenter alarms.
  entity_sync     Synchronize discovered entities.
  init_entities   Discover and create initial entities.

Environment overrides:
  BASE_DIR, CONFIG_FILE, LOG_DIR, STATE_DIR, PYTHON_BIN, ENV_FILE

An optional runtime.env file in BASE_DIR is loaded before defaults are applied.
Copy runtime.env.sample to runtime.env and set site-specific values there.
EOF
}

if [ "$#" -ne 1 ] || [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
    usage
    [ "$#" -eq 1 ] && exit 0
    exit 2
fi

data="$1"
# Default to the directory containing this installation. Callers may override
# it explicitly, for example: BASE_DIR=/opt/oracle/logan_collectors bin/run.sh metrics.
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
DEFAULT_BASE_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd -P)"

# Customers can place site-specific launcher settings in runtime.env without
# changing their existing cron entries. ENV_FILE may be used to select a
# different file. The runtime file is optional, so existing installations keep
# their current behavior until they explicitly create one from the template.
ENV_FILE="${ENV_FILE:-${BASE_DIR:-$DEFAULT_BASE_DIR}/runtime.env}"
if [ -e "$ENV_FILE" ]; then
    [ -f "$ENV_FILE" ] && [ -r "$ENV_FILE" ] || {
        echo "ERROR: Runtime environment file is not a readable regular file: $ENV_FILE" >&2
        exit 1
    }
    # shellcheck disable=SC1090
    source "$ENV_FILE"
fi

BASE_DIR="${BASE_DIR:-$DEFAULT_BASE_DIR}"
CONFIG_FILE="${CONFIG_FILE:-$BASE_DIR/config.yaml}"
LOG_DIR="${LOG_DIR:-$BASE_DIR/logs}"
STATE_DIR="${STATE_DIR:-$BASE_DIR/state}"
PYTHON_BIN="${PYTHON_BIN:-$(command -v python3 || true)}"
VERSION_FILE="$BASE_DIR/VERSION"

if [ -r "$VERSION_FILE" ]; then
    SOLUTION_VERSION="$(tr -d '[:space:]' < "$VERSION_FILE")"
    [ -n "$SOLUTION_VERSION" ] || {
        echo "ERROR: Solution version file is empty: $VERSION_FILE" >&2
        exit 1
    }
else
    SOLUTION_VERSION="unknown"
    echo "WARNING: Solution version file is missing or unreadable: $VERSION_FILE" >&2
fi

# Optional: activate venv if you ship one
if [ -d "$BASE_DIR/venv" ]; then
    [ -f "$BASE_DIR/venv/bin/activate" ] || {
        echo "ERROR: Virtual environment activation script is missing: $BASE_DIR/venv/bin/activate" >&2
        exit 1
    }
    # shellcheck disable=SC1091
    source "$BASE_DIR/venv/bin/activate"
    PYTHON_BIN="$BASE_DIR/venv/bin/python"
fi

if [ ! -x "$PYTHON_BIN" ]; then
    PYTHON_BIN="$(command -v "$PYTHON_BIN" || true)"
fi

case "$data" in
    metrics)       SCRIPT="$BASE_DIR/vmware_collector/collect_metrics.py"; OUT_FILE="metric_collector.out" ;;
    events)        SCRIPT="$BASE_DIR/vmware_collector/collect_events.py"; OUT_FILE="event_collector.out" ;;
    alarms)        SCRIPT="$BASE_DIR/vmware_collector/collect_alarms.py"; OUT_FILE="alarm_collector.out" ;;
    entity_sync)   SCRIPT="$BASE_DIR/entity_sync/entity_sync.py"; OUT_FILE="entity_synchronizer.out" ;;
    init_entities) SCRIPT="$BASE_DIR/entity_discovery/main.py"; OUT_FILE="" ;;
    *)
        echo "ERROR: Unsupported operation: $data" >&2
        usage >&2
        exit 2
        ;;
esac

preflight() {
    [ -d "$BASE_DIR" ] || { echo "ERROR: BASE_DIR does not exist: $BASE_DIR" >&2; exit 1; }
    [ -f "$CONFIG_FILE" ] && [ -r "$CONFIG_FILE" ] || { echo "ERROR: Configuration file is missing or unreadable: $CONFIG_FILE" >&2; exit 1; }
    [ -f "$SCRIPT" ] || { echo "ERROR: Collector script is missing: $SCRIPT" >&2; exit 1; }
    [ -n "$PYTHON_BIN" ] && [ -x "$PYTHON_BIN" ] || { echo "ERROR: Python executable is missing or not executable: ${PYTHON_BIN:-python3}" >&2; exit 1; }

    mkdir -p "$LOG_DIR" "$STATE_DIR"
    [ -w "$LOG_DIR" ] && [ -w "$STATE_DIR" ] || { echo "ERROR: LOG_DIR and STATE_DIR must be writable" >&2; exit 1; }
}

preflight
export CONFIG_FILE LOG_DIR STATE_DIR SOLUTION_VERSION
export COLLECTOR_ACTION="$data"

if [ "$data" = "init_entities" ]; then
    exec "$PYTHON_BIN" "$SCRIPT" --base-dir "$BASE_DIR"
fi

exec "$PYTHON_BIN" "$SCRIPT" --base-dir "$BASE_DIR" >> "$LOG_DIR/$OUT_FILE" 2>&1
