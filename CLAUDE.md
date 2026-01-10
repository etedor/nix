# NixOS Configuration

## Project Structure

- `hosts/darwin/<hostname>/` - macOS machine configurations
- `hosts/router/<hostname>/` - NixOS router configurations
- `hosts/server/<hostname>/` - NixOS server configurations
- `modules/common/` - shared modules across all platforms
- `modules/darwin/` - macOS-specific modules
- `modules/router/` - router-specific modules
- `modules/server/` - server-specific modules
- `secrets/` - agenix-encrypted secrets

## Style

- Comments: lowercase, terse
- Acronyms in comments: UPPERCASE (DSCP, VLAN, TCP, UDP, MAC, IP, SSH, URL, DNS, DHCP, etc.)
- Product names: capitalize properly (Mac, macOS, Mozilla, WireGuard)
- Technical units: preserve casing (KiB, MiB, GiB for bytes; Gbit, Mbit for bandwidth)
- Shell scripts: use `#!/usr/bin/env bash` shebang
- User shell: fish (not bash)

## Validation

A PostToolUse hook runs `nix flake check` after file edits to catch errors early.

For comprehensive validation of a specific host:

**Darwin hosts:**

```bash
nix build .#darwinConfigurations.<hostname>.config.system.build.toplevel --dry-run
```

**NixOS hosts:**

```bash
nixos-rebuild dry-build --flake .#<hostname>
```

**rt-ggz has an out-of-band management interface:** use `eric@rt-ggz.ma` as target-host.

## Hosts

- **Darwin:** carbon, garage, machina
- **NixOS routers:** rt-ggz, rt-sea
- **NixOS servers:** duke
