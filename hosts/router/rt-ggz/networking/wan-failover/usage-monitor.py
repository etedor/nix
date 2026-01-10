#!/usr/bin/env python3

import json
import os
import subprocess
import sys
from datetime import datetime
from pathlib import Path
import re

from pushover_complete import PushoverAPI

# nix-substituted configuration
INTERFACE = "@interface@"
THRESHOLDS = "@thresholds@".split(",")
RESET_DAY = int("@resetDay@")

VNSTAT = "@vnstat@/bin/vnstat"
PUSHOVER_PATH = "@pushoverPath@"
STATE_DIR = Path("/run/wan-usemon")
STATE_DIR.mkdir(exist_ok=True)


def log(level, message):
    """Log a message with the specified level."""
    print(f"[{level}] {message}", flush=True)


def log_info(message):
    log("INFO", message)


def log_warn(message):
    log("WARN", message)


def log_error(message):
    log("ERROR", message)


def parse_threshold(threshold_str):
    """Parse a threshold string into a value in GB."""
    # default to GB if no unit specified
    if threshold_str.replace(".", "", 1).isdigit():
        return float(threshold_str)

    # parse value and unit
    match = re.match(r"(\d+(?:\.\d+)?)\s*([KMG]B?)?", threshold_str, re.IGNORECASE)
    if not match:
        log_error(f"Invalid threshold format: {threshold_str}")
        return 0

    value = float(match.group(1))
    unit = match.group(2).upper() if match.group(2) else "GB"

    # convert to GB
    if unit in ("K", "KB"):
        return value / (1024 * 1024)
    elif unit in ("M", "MB"):
        return value / 1024
    elif unit in ("G", "GB"):
        return value
    else:
        log_error(f"Unknown unit: {unit}")
        return 0


def format_threshold(value_gb):
    """Format a threshold value in GB for display."""
    if value_gb >= 1:
        return f"{value_gb:.2f}GB"
    elif value_gb >= 0.001:
        return f"{value_gb * 1024:.2f}MB"
    else:
        return f"{value_gb * 1024 * 1024:.2f}KB"


def get_pushover_credentials():
    """Get Pushover credentials from the secret file."""
    if not os.path.isfile(PUSHOVER_PATH):
        log_error(f"Pushover secret file not found: {PUSHOVER_PATH}")
        return None, None

    try:
        with open(PUSHOVER_PATH, "r") as f:
            content = f.read()

        user_key = None
        api_token = None

        for line in content.splitlines():
            if line.startswith("USER_KEY="):
                user_key = line.split("=", 1)[1].strip().strip("\"'")
            elif line.startswith("API_TOKEN="):
                api_token = line.split("=", 1)[1].strip().strip("\"'")

        if not user_key or not api_token:
            log_error("Pushover credentials not found in secret file")
            return None, None

        return user_key, api_token
    except Exception as e:
        log_error(f"Error reading Pushover credentials: {e}")
        return None, None


def send_pushover_notification(title, message, priority=0):
    """Send a notification via Pushover."""
    user_key, api_token = get_pushover_credentials()

    if not user_key or not api_token:
        log_error("Failed to get Pushover credentials")
        return False

    log_info(f"Sending Pushover notification: {title} - {message}")

    try:
        client = PushoverAPI(api_token)
        params = {"title": title, "priority": priority}

        if priority == 2:
            params["expire"] = 3600  # 1 hour
            params["retry"] = 300  # 5 minutes

        client.send_message(user_key, message, **params)
        return True
    except Exception as e:
        log_error(f"Failed to send Pushover notification: {e}")
        return False


def check_reset_notifications():
    """Check if we need to reset the notification state files."""
    current_day = datetime.now().day
    reset_state_file = STATE_DIR / f"{INTERFACE}_reset.state"

    if current_day == RESET_DAY:
        if not reset_state_file.exists():
            log_info(
                f"Data usage reset day ({RESET_DAY}). Clearing notification states."
            )

            for state_file in STATE_DIR.glob(f"{INTERFACE}_*.notified"):
                try:
                    state_file.unlink()
                except Exception as e:
                    log_error(f"Failed to remove state file {state_file}: {e}")

            send_pushover_notification(
                "Data Usage Reset",
                f"Monthly data usage for {INTERFACE} has been reset. New billing cycle started.",
                0,
            )

            try:
                reset_state_file.touch()
            except Exception as e:
                log_error(f"Failed to create reset state file: {e}")
    elif reset_state_file.exists():
        # remove reset state file when past the reset day
        try:
            reset_state_file.unlink()
        except Exception as e:
            log_error(f"Failed to remove reset state file: {e}")


def get_current_month_usage():
    """Get the current month's usage data using vnstat's JSON output."""
    try:
        result = subprocess.run(
            [VNSTAT, "-i", INTERFACE, "--json"],
            capture_output=True,
            text=True,
            check=True,
            timeout=30,
        )

        data = json.loads(result.stdout)

        now = datetime.now()
        current_year = now.year
        current_month = now.month

        month_data = None
        for month in data["interfaces"][0]["traffic"]["month"]:
            if (
                month["date"]["year"] == current_year
                and month["date"]["month"] == current_month
            ):
                month_data = month
                break

        if not month_data:
            log_warn(f"No data found for current month on {INTERFACE}")
            return {"used_bytes": 0, "used_gb": 0}

        total_bytes = month_data["rx"] + month_data["tx"]
        total_gb = round(total_bytes / (1024**3), 2)

        return {"used_bytes": total_bytes, "used_gb": total_gb}
    except subprocess.TimeoutExpired:
        log_error("Timeout while running vnstat command")
        return None
    except (subprocess.CalledProcessError, json.JSONDecodeError, KeyError) as e:
        log_error(f"Failed to get current month usage: {e}")
        return None


def check_threshold(
    threshold_gb, threshold_str, is_limit, monthly_limit_gb, sorted_threshold_pairs
):
    """Check if a threshold has been exceeded and notify if needed."""
    safe_threshold_str = threshold_str.replace(" ", "_").replace("/", "_")
    state_file = STATE_DIR / f"{INTERFACE}_{safe_threshold_str}.notified"

    if state_file.exists():
        return True

    # skip if already notified for a higher threshold
    if not is_limit:
        for t_gb, t_str in sorted_threshold_pairs:
            if t_gb <= threshold_gb:
                break

            t_safe = t_str.replace(" ", "_").replace("/", "_")
            if (STATE_DIR / f"{INTERFACE}_{t_safe}.notified").exists():
                return True

    usage_data = get_current_month_usage()
    if not usage_data:
        return False

    used_gb = usage_data["used_gb"]
    if used_gb < threshold_gb:
        return False

    used_percentage = round((used_gb / monthly_limit_gb) * 100, 1)
    remaining_gb = round(monthly_limit_gb - used_gb, 2)

    if is_limit:
        title = "Data Usage LIMIT EXCEEDED"
        message = (
            f"ALERT: Data usage on {INTERFACE} has exceeded the monthly limit of {threshold_str}! "
            f"Current usage: {used_gb:.2f}GB ({used_percentage}%)"
        )
        priority = 2
    else:
        title = f"Data Usage Warning: {threshold_str}"
        message = (
            f"Data usage on {INTERFACE} has reached {used_gb:.2f}GB "
            f"({used_percentage}% of {format_threshold(monthly_limit_gb)} limit). "
            f"{remaining_gb:.2f}GB remaining."
        )
        priority = 1 if used_percentage >= 90 else 0

    if send_pushover_notification(title, message, priority):
        try:
            state_file.touch()
            return True
        except Exception as e:
            log_error(f"Failed to create state file {state_file}: {e}")

    return False


def main():
    """Main function."""
    try:
        log_info(f"Starting data usage monitor for {INTERFACE}")
        check_reset_notifications()

        threshold_pairs = []
        for t in THRESHOLDS:
            gb_value = parse_threshold(t)
            log_info(f"Parsed threshold: {t} -> {gb_value:.2f}GB")
            threshold_pairs.append((gb_value, t))

        sorted_threshold_pairs = sorted(
            threshold_pairs, key=lambda x: x[0], reverse=True
        )
        monthly_limit_gb, monthly_limit_str = sorted_threshold_pairs[0]

        log_info(
            f"Monthly limit: {monthly_limit_str} ({monthly_limit_gb:.2f}GB), Reset day: {RESET_DAY}"
        )

        usage_data = get_current_month_usage()
        if not usage_data:
            log_error("Failed to get current month usage, exiting")
            return 1

        used_gb = usage_data["used_gb"]
        used_percentage = round((used_gb / monthly_limit_gb) * 100, 1)
        remaining_gb = round(monthly_limit_gb - used_gb, 2)

        log_info(
            f"Current data usage: {used_gb:.2f}GB / {monthly_limit_gb:.2f}GB ({used_percentage}%), {remaining_gb:.2f}GB remaining"
        )

        for i, (threshold_gb, threshold_str) in enumerate(sorted_threshold_pairs):
            is_limit = i == 0
            check_threshold(
                threshold_gb,
                threshold_str,
                is_limit,
                monthly_limit_gb,
                sorted_threshold_pairs,
            )

        log_info("Data usage check complete")
        return 0

    except Exception as e:
        log_error(f"Unhandled exception in main function: {e}")
        return 1


if __name__ == "__main__":
    sys.exit(main())
