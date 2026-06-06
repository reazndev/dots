#!/usr/bin/env python3
"""Test script to debug Kimi API connectivity."""

import json
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
from usage_tracker import fetch_kimi

# Enable debug logging
os.environ["USAGE_DEBUG"] = "1"

# Try loading config
CONFIG_PATH = os.path.expanduser("~/.config/quickshell/usage.json")
config = {"enabled": False, "token": ""}
try:
    with open(CONFIG_PATH) as f:
        cfg = json.load(f)
        kimi_cfg = cfg.get("providers", {}).get("kimi", {})
        config["enabled"] = kimi_cfg.get("enabled", False)
        config["token"] = kimi_cfg.get("token", "")
except Exception as e:
    print(f"Could not load config: {e}")

# Also check env var
env_token = os.environ.get("KIMI_AUTH_TOKEN") or os.environ.get("KIMI_MANUAL_COOKIE")
if env_token:
    print("Found KIMI_AUTH_TOKEN / KIMI_MANUAL_COOKIE in environment")
    config["token"] = env_token

if not config["token"]:
    print("ERROR: No Kimi token found in config or environment")
    print(f"  Config path: {CONFIG_PATH}")
    print("  Set either config.providers.kimi.token or KIMI_AUTH_TOKEN env var")
    sys.exit(1)

print(f"Token source: {'config' if not env_token else 'environment'}")
print(f"Token length: {len(config['token'])}")
print(f"Token starts with: {config['token'][:30]}...")
print()

# Run the fetch
result = fetch_kimi(config)
print()
print("=" * 50)
print("Result:")
print(json.dumps(result, indent=2, default=str))
