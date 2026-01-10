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

## Workflow

**ALWAYS follow this workflow for any file changes, regardless of size:**

1. Pull latest changes: `git pull --ff-only`
2. Create a branch before making changes (never commit directly to master)
3. Use the appropriate prefix: `feat/`, `fix/`, `chore/`, or `refactor/`
4. Validate with a dry-run build before committing (see Validation section)
5. Only push to remote when explicitly requested

**Branching:**

```
feat/<name>     new feature
fix/<name>      bug fix
chore/<name>    maintenance, dependency updates
refactor/<name> code restructuring
```

**Development cycle:**

1. `git checkout -b feat/<name>` or `fix/<name>`
2. make changes (hook runs `nix flake check` after edits)
3. test locally: `sudo darwin-rebuild switch --flake .#machina`
4. commit: `git add . && git commit -m "<description>"`
5. merge to master:
   ```bash
   git checkout master
   git merge <branch>
   git push
   git branch -d <branch>
   ```

**Deploying:**

```bash
# darwin (local)
sudo darwin-rebuild switch --flake .#<hostname>

# nixos (remote)
deploy .#<hostname>
# or: nixos-rebuild switch --flake .#<hostname> --target-host eric@<hostname>
```

**Updating inputs:**

```bash
nix flake update           # all inputs
nix flake update <input>   # single input (e.g., nixpkgs, private)
```
