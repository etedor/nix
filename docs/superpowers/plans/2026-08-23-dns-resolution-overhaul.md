# DNS Resolution Overhaul Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Kill the `parallel_best`-races-dead-upstreams SERVFAIL bug and make on-prem rt-ggz a health-gated anycast DNS provider, so no client's DNS depends on a server that can vanish.

**Architecture:** Three changes from the spec: (1) each router's Blocky forwards only to its own local Unbound (decouple); (2) rt-ggz binds + advertises the anycast `/32` like the VPSes already do; (3) a shared `modules/router` health-gate service advertises the anycast `/32` only while the router can actually resolve (unit-liveness AND a direct `kdig` probe to its real upstream), withdrawing it via `redistribute connected` otherwise. Resolution methods are unchanged (rt-ggz → Cloudflare DoT, VPS → roots).

**Tech Stack:** NixOS flake, systemd-networkd, FRR (BGP/zebra `redistribute connected`), Blocky, Unbound, agenix, deploy-rs. Probe tool: `kdig` (`knot-dnsutils`). Root IPs from `pkgs.dns-root-data`.

## Global Constraints

Copied verbatim from the operating context — every task inherits these:

- **NEVER run `agenix -r`** (or any partial agenix) from an agent — it corrupts secrets. No secret material changes in this plan; if a task appears to need one, stop and ask.
- **Do NOT delete any files on any machine or disk.** Back up with `mv … .hm-backup` if a clobber blocks activation. This applies to remote hosts too.
- **Always keep a reboot / `nix rollback` escape hatch** for every live change. deploy-rs auto-rolls-back if activation isn't confirmed within `confirmTimeout` (rt-ggz 120s; rt-sea/rt-sea2 have their own). Never disable that.
- **Deploy runs from machina** (Claude session: carbon → ssh → machina). `SSH_AUTH_SOCK` must point at machina's launchd keychain agent so the forwarded user key satisfies `pam_sshAgentAuth` sudo on the routers. `sudo -n` is a *false negative* on routers — do not use it to conclude sudo is broken.
- **Deploy order is fixed:** rt-sea → rt-sea2 → verify both healthy → rt-ggz. Do not touch rt-ggz until both VPSes are confirmed healthy.
- **Same-version deploys only** here (no NixOS major bump), so live `switch` is safe; if a task ever crosses a systemd major bump, use `boot` + reboot instead.
- Style: comments lowercase and terse; acronyms uppercase (DNS, DoT, VIP, BGP); shebang `#!/usr/bin/env bash`.

## Verification model (infra, not unit tests)

NixOS modules do not unit-test cleanly. Each task's "test" is one or more of: `nix flake check`, a host dry-build, `nix eval` of the rendered value, or a **live probe** after deploy (`kdig`, `vtysh`, `journalctl`) via `claude-run` (read-only) or agent-forwarded ssh. Commands and expected output are given explicitly. This substitutes for the TDD red/green loop; keep the "run it and see the expected output" discipline.

Dry-build a NixOS host:
```bash
nixos-rebuild dry-build --flake .#<hostname>
```

---

## File Structure

**New:**
- `modules/router/options/anycast-health.nix` — the shared health-gate: option interface (`et42.router.anycastHealth`), the poll-loop script (role-based `kdig` probe + hysteresis + `ip addr add/del`), the systemd service, and `IPFreeBind` on Blocky. One responsibility: gate the anycast `/32` on real resolvability.

**Modified:**
- `modules/router/options/default.nix` — import the new module.
- `hosts/router/rt-sea/services/dns.nix` — Blocky upstream → local Unbound only; enable `anycastHealth` (roots probe).
- `hosts/router/rt-sea/networking/default.nix` — drop the static anycast address from `lo53` (the gate owns it now).
- `hosts/router/rt-sea2/services/dns.nix` — same as rt-sea (roots probe).
- `hosts/router/rt-sea2/networking/default.nix` — same as rt-sea.
- `hosts/router/rt-ggz/services/dns/default.nix` — Blocky upstream → local Unbound only; add anycast to `listenAddress`; enable `anycastHealth` (Cloudflare-DoT probe).
- `hosts/router/rt-ggz/networking/interfaces.nix` — add `lo53` dummy netdev + address-less network.

**Unchanged (verified, no edit needed):**
- FRR configs already `redistribute connected route-map RM-RFC1918_V4`; `RM-RFC1918_V4` permits `10.0.0.0/8 ge 8 le 32`, which covers `10.127.255.53/32`. So the gate adding the address to `lo53` is auto-advertised; removing it withdraws. No FRR edit on any host.
- rt-ggz firewall `dns` rule accepts `53` from `rfc1918` to **any** destination (no `dips`), so DNS to the anycast VIP is already permitted. No firewall edit on rt-ggz.
- Unbound configs (rt-ggz Cloudflare DoT, VPS roots) — unchanged.

---

## Task 1: Shared health-gate module

**Files:**
- Create: `modules/router/options/anycast-health.nix`
- Modify: `modules/router/options/default.nix:3-13`

**Interfaces:**
- Consumes: `globals.anycast.dns` (the VIP string, `10.127.255.53`); `pkgs.dns-root-data` (`/root.hints`); `pkgs.knot-dnsutils` (`kdig`).
- Produces: option `et42.router.anycastHealth = { enable; address; device; probe; interval; failThreshold; okThreshold; }` where `probe ∈ { "cloudflare-dot", "roots" }`. When enabled: `systemd.services.anycast-health` (the gate) and `systemd.services.blocky.serviceConfig.IPFreeBind = true`.

- [ ] **Step 1: Write the module**

Create `modules/router/options/anycast-health.nix`:

```nix
{
  config,
  lib,
  pkgs,
  globals,
  ...
}:

let
  cfg = config.et42.router.anycastHealth;
  rootHints = "${pkgs.dns-root-data}/root.hints";

  # poll loop: advertise the anycast /32 only while the router can actually resolve.
  # health = unit-liveness (blocky+unbound active) AND path (direct kdig to real upstream).
  # every probe target is a literal IP so failed->live works with local DNS down.
  gate = pkgs.writeShellApplication {
    name = "anycast-health";
    runtimeInputs = [
      pkgs.knot-dnsutils
      pkgs.iproute2
      pkgs.systemd
      pkgs.gawk
      pkgs.coreutils
    ];
    text = ''
      set -uo pipefail

      ADDR="${cfg.address}"
      DEV="${cfg.device}"
      MODE="${cfg.probe}"
      INTERVAL=${toString cfg.interval}
      FAIL_THRESHOLD=${toString cfg.failThreshold}
      OK_THRESHOLD=${toString cfg.okThreshold}

      have_addr() { ip -4 addr show dev "$DEV" 2>/dev/null | grep -qw "$ADDR"; }
      add_addr()  { ip addr add "$ADDR/32" dev "$DEV" 2>/dev/null || true; }
      del_addr()  { ip addr del "$ADDR/32" dev "$DEV" 2>/dev/null || true; }

      # DoT reachability to Cloudflare; literal IPs, hostname is SNI/cert only (no lookup)
      probe_cloudflare() {
        local ip
        for ip in 1.1.1.1 1.0.0.1; do
          if kdig +tls +tls-hostname=cloudflare-dns.com +timeout=2 +retry=0 \
               "@$ip" cloudflare.com A 2>/dev/null | grep -q "status: NOERROR"; then
            return 0
          fi
        done
        return 1
      }

      # root reachability; root IPs read from the hints file (store read, not DNS)
      probe_roots() {
        local ips ip
        ips=$(awk '$4=="A"{print $5}' "${rootHints}" | shuf | head -3)
        for ip in $ips; do
          if kdig +timeout=2 +retry=0 "@$ip" . NS 2>/dev/null | grep -q "status: NOERROR"; then
            return 0
          fi
        done
        return 1
      }

      fails=0
      oks=0

      while :; do
        live=1
        systemctl is-active --quiet blocky  || live=0
        systemctl is-active --quiet unbound || live=0

        path=0
        if [ "$live" = 1 ]; then
          if [ "$MODE" = "cloudflare-dot" ]; then
            probe_cloudflare && path=1
          else
            probe_roots && path=1
          fi
        fi

        if [ "$live" = 1 ] && [ "$path" = 1 ]; then
          oks=$((oks + 1)); fails=0
          # reconcile against ACTUAL state so networkd stripping self-heals
          if [ "$oks" -ge "$OK_THRESHOLD" ] && ! have_addr; then
            add_addr
            echo "anycast: healthy (oks=$oks) -> advertise $ADDR on $DEV"
          fi
        else
          fails=$((fails + 1)); oks=0
          if [ "$fails" -ge "$FAIL_THRESHOLD" ] && have_addr; then
            del_addr
            echo "anycast: unhealthy (fails=$fails live=$live path=$path) -> withdraw $ADDR"
          fi
        fi

        sleep "$INTERVAL"
      done
    '';
  };
in
{
  options.et42.router.anycastHealth = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Health-gate the anycast DNS /32: advertise only while the router can resolve.";
    };

    address = lib.mkOption {
      type = lib.types.str;
      default = globals.anycast.dns;
      description = "Anycast VIP to gate (added/removed on the device below).";
    };

    device = lib.mkOption {
      type = lib.types.str;
      default = "lo53";
      description = "Dummy interface that carries the anycast /32 (must exist; address is managed by the gate).";
    };

    probe = lib.mkOption {
      type = lib.types.enum [ "cloudflare-dot" "roots" ];
      description = "Path probe: 'cloudflare-dot' for home routers, 'roots' for VPS routers.";
    };

    interval = lib.mkOption {
      type = lib.types.int;
      default = 5;
      description = "Seconds between polls.";
    };

    failThreshold = lib.mkOption {
      type = lib.types.int;
      default = 3;
      description = "Consecutive failed polls before withdrawing the /32 (hysteresis).";
    };

    okThreshold = lib.mkOption {
      type = lib.types.int;
      default = 2;
      description = "Consecutive healthy polls before advertising the /32 (hysteresis).";
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.anycast-health = {
      description = "anycast DNS health gate (${cfg.address})";
      after = [
        "network-online.target"
        "blocky.service"
        "unbound.service"
        "frr.service"
      ];
      wants = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        ExecStart = lib.getExe gate;
        Restart = "always";
        RestartSec = 5;
        # fail-safe: withdraw the VIP if the gate itself dies (nothing left monitoring it)
        ExecStopPost = "${pkgs.iproute2}/bin/ip addr del ${cfg.address}/32 dev ${cfg.device}";
      };
    };

    # blocky binds the anycast VIP specifically; keep its socket valid when the gate drops the address
    systemd.services.blocky.serviceConfig.IPFreeBind = true;
  };
}
```

- [ ] **Step 2: Register the module**

Modify `modules/router/options/default.nix` imports to add `./anycast-health.nix`:

```nix
{ ... }:
{
  imports = [
    ./anycast-health.nix
    ./blocky
    ./cake.nix
    ./frr.nix
    ./kea.nix
    ./miniupnpd.nix
    ./nftables.nix
    ./knot
    ./unbound.nix
    ./wireguard
  ];
}
```

- [ ] **Step 3: Verify the module evaluates**

Run:
```bash
nix flake check 2>&1 | tail -20
```
Expected: no error about `anycast-health.nix` (option `et42.router.anycastHealth` now defined). `nix flake check` passes as before (the option is unused so far, so no host behavior changes yet).

- [ ] **Step 4: Verify the gate script builds and the probe works locally**

Run (proves `kdig` DoT to Cloudflare returns NOERROR from this network — sanity for the probe logic):
```bash
nix shell nixpkgs#knot-dnsutils -c \
  kdig +tls +tls-hostname=cloudflare-dns.com +timeout=2 @1.1.1.1 cloudflare.com A | grep "status:"
```
Expected: a line containing `status: NOERROR`.

- [ ] **Step 5: Commit**

```bash
git add modules/router/options/anycast-health.nix modules/router/options/default.nix
git commit -m "feat: shared anycast DNS health-gate module

- poll loop: advertise /32 only while blocky+unbound live AND upstream reachable
- role-based kdig probe (cloudflare-dot | roots), literal-IP targets
- hysteresis; ip addr add/del gates redistribute-connected; IPFreeBind on blocky"
```

---

## Task 2: Decouple + health-gate rt-sea

**Files:**
- Modify: `hosts/router/rt-sea/services/dns.nix:24-30` (Blocky upstream), add `anycastHealth`
- Modify: `hosts/router/rt-sea/networking/default.nix:49-52` (drop static lo53 address)

**Interfaces:**
- Consumes: `et42.router.anycastHealth` from Task 1.
- Produces: rt-sea Blocky forwards only to its local Unbound; the gate (roots probe) owns `lo53`'s anycast address.

- [ ] **Step 1: Decouple Blocky + enable the gate**

In `hosts/router/rt-sea/services/dns.nix`, change the Blocky `upstream.servers` to local Unbound only, and delete the now-unused `rt-sea2-unbound` binding. Replace lines 8-30 region so the `let` drops `rt-sea2` if unused elsewhere (it is still used? check: only in `rt-sea2-unbound`; remove both). Concretely:

Change the `let` block:
```nix
let
  rt-sea = globals.routers.rt-sea;
  lo0 = rt-sea.interfaces.lo0;

  rt-sea-unbound = "${rt-sea.interfaces.lo0}:5353";
in
```

Change the Blocky `upstream`:
```nix
    upstream = {
      servers = [
        rt-sea-unbound
      ];
      timeout = "500ms";
    };
```

Add the gate at the end of the attrset (before the final `}`), after the `age.secrets.knot-tsig-key` block:
```nix
  # advertise the anycast VIP only while this VPS can recurse from roots
  et42.router.anycastHealth = {
    enable = true;
    probe = "roots";
  };
```

- [ ] **Step 2: Let the gate own the lo53 address**

In `hosts/router/rt-sea/networking/default.nix`, the `lo53` dummy netdev stays; drop the static address so the gate is the sole owner. Change the `"01-lo53"` network stanza from:
```nix
      "01-lo53" = {
        name = "lo53";
        address = [ globals.anycast.dns ];
      };
```
to:
```nix
      "01-lo53" = {
        name = "lo53";
        # address is managed by the anycast-health gate (see services/dns.nix)
        networkConfig.LinkLocalAddressing = "no";
        linkConfig.RequiredForOnline = "no";
      };
```

- [ ] **Step 3: Dry-build rt-sea**

Run:
```bash
nixos-rebuild dry-build --flake .#rt-sea 2>&1 | tail -20
```
Expected: builds with no evaluation error. (If `globals` is reported unused in `networking/default.nix`, keep it — it's still referenced by `01-lo0`.)

- [ ] **Step 4: Verify the rendered gate service**

Run:
```bash
nix eval --raw .#nixosConfigurations.rt-sea.config.systemd.services.anycast-health.serviceConfig.ExecStart
```
Expected: a `/nix/store/…/bin/anycast-health` path (the gate script built for rt-sea).

Run:
```bash
nix eval .#nixosConfigurations.rt-sea.config.systemd.services.blocky.serviceConfig.IPFreeBind
```
Expected: `true`.

- [ ] **Step 5: Commit**

```bash
git add hosts/router/rt-sea/services/dns.nix hosts/router/rt-sea/networking/default.nix
git commit -m "feat(rt-sea): decouple blocky to local unbound; health-gate anycast (roots)"
```

---

## Task 3: Decouple + health-gate rt-sea2

**Files:**
- Modify: `hosts/router/rt-sea2/services/dns.nix:8-30` and add `anycastHealth`
- Modify: `hosts/router/rt-sea2/networking/default.nix:54-57` (drop static lo53 address)

**Interfaces:**
- Consumes: `et42.router.anycastHealth` from Task 1.
- Produces: rt-sea2 Blocky forwards only to its local Unbound; gate (roots probe) owns `lo53`.

- [ ] **Step 1: Decouple Blocky + enable the gate**

In `hosts/router/rt-sea2/services/dns.nix`, change the `let` block:
```nix
let
  rt-sea2 = globals.routers.rt-sea2;
  lo0 = rt-sea2.interfaces.lo0;

  rt-sea2-unbound = "${rt-sea2.interfaces.lo0}:5353";
in
```

Change the Blocky `upstream`:
```nix
    upstream = {
      servers = [
        rt-sea2-unbound
      ];
      timeout = "500ms";
    };
```

Add the gate before the final `}` (after `age.secrets.knot-tsig-key`):
```nix
  # advertise the anycast VIP only while this VPS can recurse from roots
  et42.router.anycastHealth = {
    enable = true;
    probe = "roots";
  };
```

- [ ] **Step 2: Let the gate own the lo53 address**

In `hosts/router/rt-sea2/networking/default.nix`, change the `"01-lo53"` stanza from:
```nix
      "01-lo53" = {
        name = "lo53";
        address = [ globals.anycast.dns ];
      };
```
to:
```nix
      "01-lo53" = {
        name = "lo53";
        # address is managed by the anycast-health gate (see services/dns.nix)
        networkConfig.LinkLocalAddressing = "no";
        linkConfig.RequiredForOnline = "no";
      };
```

- [ ] **Step 3: Dry-build rt-sea2**

Run:
```bash
nixos-rebuild dry-build --flake .#rt-sea2 2>&1 | tail -20
```
Expected: builds with no evaluation error.

- [ ] **Step 4: Verify the rendered gate + IPFreeBind**

Run:
```bash
nix eval --raw .#nixosConfigurations.rt-sea2.config.systemd.services.anycast-health.serviceConfig.ExecStart
nix eval .#nixosConfigurations.rt-sea2.config.systemd.services.blocky.serviceConfig.IPFreeBind
```
Expected: an anycast-health store path, then `true`.

- [ ] **Step 5: Commit**

```bash
git add hosts/router/rt-sea2/services/dns.nix hosts/router/rt-sea2/networking/default.nix
git commit -m "feat(rt-sea2): decouple blocky to local unbound; health-gate anycast (roots)"
```

---

## Task 4: Deploy rt-sea and verify healthy

**Files:** none (deploy + live verification).

**Preflight (once, before deploying):** confirm the deploy environment.
```bash
hostname                                   # expect machina
echo "$SSH_AUTH_SOCK"                       # must be non-empty (keychain agent)
ssh eric@rt-sea 'true' && echo ssh-ok       # forwarded key reaches rt-sea
```
If `SSH_AUTH_SOCK` is empty, point it at machina's launchd Listeners socket before deploying (see deploy-from-machina notes). Do NOT conclude sudo is broken from `sudo -n`.

- [ ] **Step 1: Deploy rt-sea (auto-rollback armed)**

Run:
```bash
deploy .#rt-sea
```
Expected: activation succeeds and is confirmed within `confirmTimeout`. If it fails to confirm, deploy-rs rolls back automatically — investigate before retrying. Escape hatch if wedged: reboot the VPS from the provider panel (previous generation boots).

- [ ] **Step 2: Verify Blocky is decoupled (local upstream only)**

Run:
```bash
claude-run rt-sea journalctl -u blocky --no-pager -n 5
claude-run rt-sea systemctl is-active blocky unbound
```
Expected: both `active`; no upstream-connection errors.

- [ ] **Step 3: Verify the gate advertised the anycast /32**

Run:
```bash
claude-run rt-sea ip -br addr show lo53
claude-run rt-sea journalctl -u anycast-health --no-pager -n 10
```
Expected: `lo53` shows `10.127.255.53/32`; the gate log shows `advertise 10.127.255.53`.

- [ ] **Step 4: Verify BGP is originating the /32**

Run:
```bash
claude-run rt-sea vtysh -c "show ip route 10.127.255.53"
```
Expected: a connected route for `10.127.255.53/32` on `lo53`.

- [ ] **Step 5: Verify resolution through the anycast VIP works**

Run (from a home client or via claude-run on a router that can reach rt-sea's VIP):
```bash
claude-run rt-sea kdig +timeout=2 @10.127.255.53 example.com A | grep "status:"
```
Expected: `status: NOERROR`.

- [ ] **Step 6: Confirm — no code change to commit.** rt-sea is healthy. Proceed to rt-sea2 only if Steps 2–5 all passed.

---

## Task 5: Deploy rt-sea2 and verify healthy

**Files:** none (deploy + live verification).

- [ ] **Step 1: Deploy rt-sea2**

Run:
```bash
deploy .#rt-sea2
```
Expected: activation confirmed. Auto-rollback on failure; provider-panel reboot as last resort.

- [ ] **Step 2: Verify daemons + gate**

Run:
```bash
claude-run rt-sea2 systemctl is-active blocky unbound
claude-run rt-sea2 ip -br addr show lo53
claude-run rt-sea2 journalctl -u anycast-health --no-pager -n 10
```
Expected: `active`; `lo53` has `10.127.255.53/32`; log shows advertise.

- [ ] **Step 3: Verify BGP + resolution**

Run:
```bash
claude-run rt-sea2 vtysh -c "show ip route 10.127.255.53"
claude-run rt-sea2 kdig +timeout=2 @10.127.255.53 example.com A | grep "status:"
```
Expected: connected `/32` on `lo53`; `status: NOERROR`.

- [ ] **Step 4: Verify anycast health-gating actually gates (failover proof)**

Simulate an unhealthy resolver and confirm withdrawal, then recovery. Use agent-forwarded ssh (privileged; keep it reversible — we only stop/start a unit):
```bash
ssh eric@rt-sea2 'sudo systemctl stop unbound'
sleep 25   # exceed failThreshold*interval
claude-run rt-sea2 ip -br addr show lo53          # expect: no 10.127.255.53
claude-run rt-sea2 vtysh -c "show ip route 10.127.255.53"   # expect: withdrawn (or only VPS-peer/rt-sea path)
ssh eric@rt-sea2 'sudo systemctl start unbound'
sleep 20
claude-run rt-sea2 ip -br addr show lo53          # expect: 10.127.255.53 restored
```
Expected: address disappears after the fail hysteresis, reappears after unbound is back. This proves teardown + recovery.

- [ ] **Step 5: Confirm both VPSes healthy.** Do NOT proceed to rt-ggz unless rt-sea (Task 4) and rt-sea2 (Tasks 5.1–5.4) are all green.

---

## Task 6: rt-ggz becomes anycast provider + decouple

**Files:**
- Modify: `hosts/router/rt-ggz/services/dns/default.nix:14-30` (Blocky upstream local-only; add anycast to `listenAddress`), add `anycastHealth`
- Modify: `hosts/router/rt-ggz/networking/interfaces.nix:60-77` (add `lo53` netdev + address-less network)

**Interfaces:**
- Consumes: `et42.router.anycastHealth` from Task 1.
- Produces: rt-ggz Blocky forwards only to its local Unbound, binds `10.127.255.53:53`, and the gate (Cloudflare-DoT probe) advertises the `/32` from `lo53`. rt-ggz's local connected `/32` (admin distance 0) is preferred over BGP-learned VPS paths, so home clients resolve on-prem.

- [ ] **Step 1: Add the lo53 dummy on rt-ggz**

In `hosts/router/rt-ggz/networking/interfaces.nix`, add a `lo53` netdev alongside `00-lo0` (in the `netdevs` block):
```nix
      netdevs = {
        "00-lo0" = {
          netdevConfig = {
            Name = "lo0";
            Kind = "dummy";
          };
        };
        "00-lo53" = {
          netdevConfig = {
            Name = "lo53";
            Kind = "dummy";
          };
        };
      };
```
And add an address-less network for it alongside `00-lo0` (in the `networks` block), mirroring rt-ggz's lo0 style but with no `Address` (the gate manages it):
```nix
        "00-lo53" = {
          matchConfig.Name = "lo53";
          # address managed by the anycast-health gate (see services/dns/default.nix)
          networkConfig.LinkLocalAddressing = "no";
          linkConfig.RequiredForOnline = "no";
        };
```

- [ ] **Step 2: Decouple Blocky, bind the VIP, enable the gate**

In `hosts/router/rt-ggz/services/dns/default.nix`, change the `let` block to drop the remote Unbound bindings:
```nix
let
  rt-ggz = globals.routers.rt-ggz;
  things = globals.networks.ggz.things;

  rt-ggz-unbound = "${rt-ggz.interfaces.lo0}:5353";
in
```

Add the anycast VIP to Blocky `listenAddress` and make its upstream local-only:
```nix
    listenAddress = [
      rt-ggz.interfaces.lo0
      globals.anycast.dns
    ];

    upstream = {
      servers = [
        rt-ggz-unbound
      ];
      timeout = "500ms";
    };
```

Enable the gate. Add before the final `networking = { … }` block (after `age.secrets.knot-tsig-key`):
```nix
  # advertise the anycast VIP only while rt-ggz can resolve via Cloudflare DoT
  et42.router.anycastHealth = {
    enable = true;
    probe = "cloudflare-dot";
  };
```

- [ ] **Step 3: Dry-build rt-ggz**

Run:
```bash
nixos-rebuild dry-build --flake .#rt-ggz 2>&1 | tail -20
```
Expected: builds with no evaluation error.

- [ ] **Step 4: Verify rendered config**

Run:
```bash
nix eval .#nixosConfigurations.rt-ggz.config.services.blocky.settings.ports.dns
nix eval .#nixosConfigurations.rt-ggz.config.systemd.services.blocky.serviceConfig.IPFreeBind
nix eval --raw .#nixosConfigurations.rt-ggz.config.systemd.services.anycast-health.serviceConfig.ExecStart
```
Expected: `ports.dns` list includes both `"10.127.0.1:53"` and `"10.127.255.53:53"`; `IPFreeBind` is `true`; an anycast-health store path prints.

- [ ] **Step 5: Commit**

```bash
git add hosts/router/rt-ggz/services/dns/default.nix hosts/router/rt-ggz/networking/interfaces.nix
git commit -m "feat(rt-ggz): become anycast DNS provider; decouple blocky to local unbound

- add lo53 dummy; blocky binds + health-gates anycast VIP (cloudflare-dot probe)
- blocky upstream local unbound only (kill parallel_best race)"
```

---

## Task 7: Deploy rt-ggz and verify end-to-end

**Files:** none (deploy + live verification).

**Escape hatch note:** rt-ggz has out-of-band management — target `eric@rt-ggz.ma` if the primary path drops. deploy-rs auto-rollback + `confirmTimeout = 120` is armed.

- [ ] **Step 1: Deploy rt-ggz**

Run:
```bash
deploy .#rt-ggz
```
Expected: activation confirmed within 120s. If not confirmed, deploy-rs rolls back. If the box is unreachable, reconnect via `eric@rt-ggz.ma`.

- [ ] **Step 2: Verify daemons, decouple, and gate**

Run:
```bash
claude-run rt-ggz systemctl is-active blocky unbound
claude-run rt-ggz ip -br addr show lo53
claude-run rt-ggz journalctl -u anycast-health --no-pager -n 10
```
Expected: both `active`; `lo53` has `10.127.255.53/32`; gate log shows advertise.

- [ ] **Step 3: Verify rt-ggz prefers its OWN anycast /32 (on-prem, local)**

Run:
```bash
claude-run rt-ggz vtysh -c "show ip route 10.127.255.53"
```
Expected: the selected route is the **connected** `/32` on `lo53` (admin distance 0), not a BGP path via a VPS. This is what keeps home clients on-prem.

- [ ] **Step 4: Verify resolution via both the loopback and the anycast VIP**

Run:
```bash
claude-run rt-ggz kdig +timeout=2 @10.127.0.1  example.com A | grep "status:"
claude-run rt-ggz kdig +timeout=2 @10.127.255.53 example.com A | grep "status:"
```
Expected: both `status: NOERROR`.

- [ ] **Step 5: Privacy check — no cleartext :53 on the home WAN**

Run (agent-forwarded, read-only tcpdump; bounded):
```bash
ssh eric@rt-ggz 'sudo timeout 8 tcpdump -ni wan0 port 53 or port 853 2>/dev/null' &
claude-run rt-ggz kdig +timeout=2 @10.127.0.1 example.org A >/dev/null
claude-run rt-ggz kdig +timeout=2 @10.127.0.1 $(printf 'r%s.example.net' 1) A >/dev/null
wait
```
Expected: traffic to Cloudflare is `:853` only; **no cleartext `:53`** to public resolvers/authoritatives on `wan0` (internal `:53`/`:5354` to loopbacks is fine and won't appear on wan0).

- [ ] **Step 6: Verify the reported incident is fixed — no SERVFAIL with a VPS down**

Simulate both VPSes' anycast withdrawn and confirm home resolution is unaffected (rt-ggz self-serves). Reversible (stop/start units):
```bash
ssh eric@rt-sea  'sudo systemctl stop anycast-health blocky'
ssh eric@rt-sea2 'sudo systemctl stop anycast-health blocky'
sleep 10
# 100 lookups against rt-ggz; expect zero SERVFAIL
claude-run rt-ggz bash -c 'for i in $(seq 1 100); do kdig +timeout=2 @10.127.0.1 "r$i.example.com" A 2>/dev/null | grep -q "status: SERVFAIL" && echo SERVFAIL; done | wc -l'
ssh eric@rt-sea  'sudo systemctl start anycast-health blocky'
ssh eric@rt-sea2 'sudo systemctl start anycast-health blocky'
```
Expected: the SERVFAIL count is `0`. (Before this overhaul, dead VPS upstreams produced intermittent SERVFAILs — this is the regression test for the whole effort.)

- [ ] **Step 7: Restore + final state check**

Run:
```bash
claude-run rt-sea  systemctl is-active blocky anycast-health
claude-run rt-sea2 systemctl is-active blocky anycast-health
claude-run rt-ggz  ip -br addr show lo53
```
Expected: all `active`; rt-ggz still advertising the VIP. All three routers healthy and independent.

- [ ] **Step 8: Merge to main**

```bash
git checkout main
git merge feat/dns-resolution-overhaul
git push
git branch -d feat/dns-resolution-overhaul
```

---

## Deferred (NOT in this plan — confirm before starting)

- Flip client DHCP resolver order to anycast-primary (`hosts/router/rt-ggz/services/dhcp/default.nix` — swap `dnsServers` to `[ anycast.dns, rt-ggz.lo0 ]`). Open Decision #2 in the spec. Leave rt-ggz.lo0 primary for now; both already resolve on-prem, so this is a failover-behavior tweak, not a fix.
- rt-ggz2 deploy (Cloudflare DoT on T-Mobile + anycast provider, `probe = "cloudflare-dot"`).
- Full-recursion (deep-leaf) probe variant. Open Decision #3.

---

## Self-Review

**Spec coverage:**
- Change 1 (decouple) → Tasks 2, 3, 6 (Blocky upstream → local Unbound on all three). ✓
- Change 2 (on-prem anycast provider) → Task 6 (lo53 + Blocky bind + gate on rt-ggz); FRR redistribute + firewall verified already-present (File Structure "Unchanged"). ✓
- Change 3 (methods unchanged) → no Unbound edits; verified in File Structure. ✓
- Health-gating mechanism (poll loop, live AND path, role probe, literal-IP invariant, hysteresis, IPFreeBind, redistribute-connected withdrawal, floor) → Task 1. ✓
- Testing (daemon failover, path/bootstrap, privacy, SERVFAIL regression) → Tasks 4.5, 5.4, 7.5, 7.6. ✓
- Deploy order rt-sea → rt-sea2 → rt-ggz → Tasks 4/5/7 with hard gates. ✓
- Client floor (unicast secondary) → unchanged DHCP keeps rt-ggz.lo0; noted in Deferred. ✓

**Placeholder scan:** No TBD/TODO; all code blocks are complete; every probe/verify command has expected output. ✓

**Type/name consistency:** `et42.router.anycastHealth.{enable,address,device,probe,interval,failThreshold,okThreshold}` defined in Task 1 and consumed identically in Tasks 2/3/6; `probe` values `"roots"`/`"cloudflare-dot"` match the enum; `lo53`/`anycast-health`/`IPFreeBind` names consistent across tasks. ✓

**Known trade-off (documented, not a gap):** `ExecStopPost` withdraws the VIP on gate restart, so a deploy briefly drops the anycast (~10s) before the gate re-advertises; acceptable given hysteresis + the rt-ggz unicast floor.
