#
# Copyright (c) 2026 Oracle, Inc.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#
import os
import logging
import logging.config
import yaml

def get_runtime_dir(basedir, environment_name, default_name):
    return os.path.abspath(os.environ.get(environment_name, os.path.join(basedir, default_name)))

def get_config_file(basedir):
    return os.path.abspath(os.environ.get("CONFIG_FILE", os.path.join(basedir, "config.yaml")))

def get_logs_dir(basedir):
    return get_runtime_dir(basedir, "LOG_DIR", "logs")

def get_checkpoint_file(basedir, collector_name):
    state_dir = get_runtime_dir(basedir, "STATE_DIR", "state")
    os.makedirs(state_dir, exist_ok=True)

    return os.path.join(state_dir, f"{collector_name}.json")

def get_solution_user_agent():
    version = os.environ.get("SOLUTION_VERSION", "unknown")
    action = os.environ.get("COLLECTOR_ACTION", "unknown")
    return f"vmware-logan-solution/{version} ({action})"

def validate_basedir(basedir):
    basedir = os.path.abspath(basedir)

    if not os.path.isdir(basedir):
        raise ValueError(f"Base dir does not exist: {basedir}")

    config_file = get_config_file(basedir)
    if not os.path.isfile(config_file):
        raise ValueError(f"Missing configuration file: {config_file}")

    return basedir

def setup_logging(base_dir, collector_name, level="INFO", console=False):
    logs_dir = get_logs_dir(base_dir)
    os.makedirs(logs_dir, exist_ok=True)

    log_file = os.path.join(logs_dir, f"{collector_name}.log")

    config = {
        "version": 1,
        "disable_existing_loggers": False,  # 🔥 THIS IS THE KEY
        "formatters": {
            "standard": {
                "format": "%(asctime)s [%(levelname)s] %(name)s: %(message)s"
            }
        },
        "handlers": {
            "file": {
                "class": "logging.handlers.RotatingFileHandler",
                "level": level,
                "formatter": "standard",
                "filename": log_file,
                "maxBytes": 10 * 1024 * 1024,
                "backupCount": 5
            },
        },
        "root": {
            "handlers": ["file"],
            "level": level
        }
    }

    if console:
        config["handlers"]["console"] = {
            "class": "logging.StreamHandler",
            "level": level,
            "formatter": "standard"
        }
        config["root"]["handlers"].append("console")

    logging.config.dictConfig(config)

    logger = logging.getLogger(__name__)
    logger.info("Logging initialized: %s", log_file)
    logger.info(
        "Starting VMware solution: version=%s action=%s",
        os.environ.get("SOLUTION_VERSION", "unknown"),
        os.environ.get("COLLECTOR_ACTION", "unknown"),
    )


def load_config(config_file):
    """
    Load YAML configuration file and return dict.
    """
    with open(config_file, "r") as f:
        return yaml.safe_load(f)
