import os
import logging
import logging.config
import yaml

def get_checkpoint_file(basedir, collector_name):
    state_dir = os.path.join(basedir, "state")
    os.makedirs(state_dir, exist_ok=True)

    return os.path.join(state_dir, f"{collector_name}.json")

def validate_basedir(basedir):
    basedir = os.path.abspath(basedir)

    if not os.path.isdir(basedir):
        raise ValueError(f"Base dir does not exist: {basedir}")

    config_file = os.path.join(basedir, "config.yaml")
    if not os.path.isfile(config_file):
        raise ValueError(f"Missing config.yaml in {basedir}")

    return basedir

def setup_logging(base_dir, collector_name, level="INFO", console=False):
    logs_dir = os.path.join(base_dir, "logs")
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

    logging.getLogger(__name__).info("Logging initialized: %s", log_file)


def load_config(config_file):
    """
    Load YAML configuration file and return dict.
    """
    with open(config_file, "r") as f:
        return yaml.safe_load(f)

