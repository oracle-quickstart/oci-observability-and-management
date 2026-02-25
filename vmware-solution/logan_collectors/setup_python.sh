#!/usr/bin/env bash

set -e

REQUIRED_PY_VERSION="3.6"
REQUIREMENTS_FILE="requirements.txt"

echo "=== Checking Python version ==="

# Find python3 executable
if command -v python3 >/dev/null 2>&1; then
    PY_BIN=$(command -v python3)
else
    echo "Python3 not found. Installing..."

    # Detect OS and install python3 + pip
    if [ -f /etc/debian_version ]; then
        sudo apt-get update
        sudo apt-get install -y python3 python3-pip
    elif [ -f /etc/redhat-release ]; then
        sudo yum install -y python3 python3-pip
    elif [ -f /etc/os-release ]; then
        . /etc/os-release
        case "$ID" in
            amzn)
                sudo yum install -y python3 python3-pip
                ;;
            sles|opensuse*)
                sudo zypper install -y python3 python3-pip
                ;;
            *)
                echo "Unsupported Linux distribution. Install Python 3.8+ manually."
                exit 1
                ;;
        esac
    fi

    PY_BIN=$(command -v python3)
fi

# Validate Python version
PY_VERSION=$($PY_BIN -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')")

if $PY_BIN - <<EOF
import sys
required = tuple(map(int, "$REQUIRED_PY_VERSION".split(".")))
current = sys.version_info[:2]
if current < required:
    raise SystemExit(1)
EOF
then
    echo "Python version OK: $PY_VERSION"
else
    echo "Python version $PY_VERSION is less than required $REQUIRED_PY_VERSION"
    exit 1
fi

echo "=== Ensuring pip is installed ==="

if ! $PY_BIN -m pip --version >/dev/null 2>&1; then
    echo "pip not found, installing..."
    curl -sS https://bootstrap.pypa.io/get-pip.py -o get-pip.py
    sudo $PY_BIN get-pip.py
    rm -f get-pip.py
fi

echo "=== Installing Python modules from $REQUIREMENTS_FILE ==="

if [ ! -f "$REQUIREMENTS_FILE" ]; then
    echo "ERROR: requirements.txt not found in current directory!"
    exit 1
fi

sudo $PY_BIN -m pip install --upgrade pip
sudo $PY_BIN -m pip install  --upgrade --ignore-installed -r "$REQUIREMENTS_FILE"

echo "=== DONE ==="
echo "Python: $($PY_BIN --version)"
echo "Pip: $($PY_BIN -m pip --version)"

