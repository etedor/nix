import re
import sys

import paramiko
from netmiko import ConnectHandler

SSH_CONFIG = "/Users/eric/.ssh/config"
RSA_KEY = "/Users/eric/.ssh/claude_rsa"
ED25519_KEY = "/Users/eric/.ssh/claude_ed25519"

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


def main():
    if len(sys.argv) < 3:
        print("usage: switch-cli <host> <command...>", file=sys.stderr)
        sys.exit(1)

    host = sys.argv[1]
    command = " ".join(sys.argv[2:])

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
    output = conn.send_command(command)
    conn.disconnect()
    print(output)


if __name__ == "__main__":
    main()
