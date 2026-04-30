import os
import re
import sys

import paramiko
from netmiko import (
    ConnectHandler,
    NetmikoAuthenticationException,
    NetmikoTimeoutException,
)

HOME = os.path.expanduser("~")
SSH_CONFIG = os.environ.get("CLAUDE_SSH_CONFIG", f"{HOME}/.ssh/config")
RSA_KEY = os.environ.get("CLAUDE_RSA_KEY", f"{HOME}/.ssh/claude_rsa")
ED25519_KEY = os.environ.get("CLAUDE_ED25519_KEY", f"{HOME}/.ssh/claude_ed25519")

# IOS: rewrite 'show run*' variants to 'more system:running-config'
IOS_SHOW_RUN = re.compile(r"^show\s+run", re.IGNORECASE)

# SSH banner -> (netmiko device_type, legacy crypto?)
BANNER_MAP = {
    "RomSShell": ("ruckus_fastiron", True),
    "Cisco": ("cisco_ios", True),
}
DEFAULT_TYPE = ("arista_eos", False)


def detect_device_type(host: str, port: int = 22) -> tuple[str, bool]:
    """Identify NOS from SSH banner. Returns (device_type, is_legacy)."""
    t = paramiko.Transport((host, port))
    t.start_client()
    banner = t.remote_version
    t.close()
    for prefix, info in BANNER_MAP.items():
        if prefix in banner:
            return info
    return DEFAULT_TYPE


def run(host: str, command: str) -> str:
    device_type, legacy = detect_device_type(host)

    if device_type == "cisco_ios" and IOS_SHOW_RUN.match(command):
        command = "more system:running-config"

    if legacy:
        pkey = paramiko.RSAKey.from_private_key_file(RSA_KEY)
        extra = {
            "ssh_config_file": SSH_CONFIG,
            "disabled_algorithms": {"pubkeys": ["rsa-sha2-256", "rsa-sha2-512"]},
        }
    else:
        pkey = paramiko.Ed25519Key.from_private_key_file(ED25519_KEY)
        extra = {}

    conn = ConnectHandler(
        device_type=device_type,
        host=host,
        username="claude",
        pkey=pkey,
        **extra,
    )
    # strip timestamp from custom prompts like "[22:29:08] sw-garage#"
    conn.base_prompt = re.sub(r"^\[[\d:]+\]\s*", "", conn.base_prompt)
    output = conn.send_command(command)
    conn.disconnect()
    return output


def main():
    args = sys.argv[1:]
    debug = False
    if args and args[0] == "--debug":
        debug = True
        args = args[1:]

    if len(args) < 2:
        print("usage: switch-cli [--debug] <host> <command...>", file=sys.stderr)
        sys.exit(2)

    host = args[0]
    command = " ".join(args[1:])

    try:
        print(run(host, command))
    except NetmikoAuthenticationException as e:
        if debug:
            raise
        print(f"error: switch auth failed for {host}: {e}", file=sys.stderr)
        sys.exit(3)
    except NetmikoTimeoutException as e:
        if debug:
            raise
        print(f"error: switch timeout for {host}: {e}", file=sys.stderr)
        sys.exit(4)
    except paramiko.SSHException as e:
        if debug:
            raise
        print(f"error: ssh transport failed for {host}: {e}", file=sys.stderr)
        sys.exit(5)
    except OSError as e:
        if debug:
            raise
        print(f"error: connect failed for {host}: {e}", file=sys.stderr)
        sys.exit(6)


if __name__ == "__main__":
    main()
