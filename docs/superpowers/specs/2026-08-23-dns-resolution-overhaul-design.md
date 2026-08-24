# DNS Resolution Overhaul — Design

**Date:** 2026-08-23
**Status:** Approved design, pending implementation plan
**Scope:** rt-ggz, rt-sea, rt-sea2 DNS config; rt-ggz becomes an anycast DNS provider. rt-ggz2 / rt-sea3 accommodated but not deployed here.

## Context

"Internet feels weird" was traced to intermittent client `SERVFAIL`s. Two independent gaps caused it, and this design fixes both.

**Gap 1 — Blocky races dead upstreams.** Every router's Blocky forwards to the *same three unicast Unbound loopbacks* (`10.127.0.1`, `10.127.100.1`, `10.127.101.1` on `:5353`) with `strategy = parallel_best`. `parallel_best` picks 2 of the 3 per cache-miss query and races them. The two remote Unbounds live on the VPSes and are only reachable via loopback `/32`s advertised over the WireGuard tunnels by BGP. When a VPS dies or its BGP session drops, that `/32` vanishes and the address falls into rt-ggz's catch-all `blackhole 10.0.0.0/8` → the query fails instantly (`connect: invalid argument`). With **both** remote upstreams down, ~⅓ of cache-miss queries draw the two dead ones → client `SERVFAIL`. Cached answers still work, so it presents as intermittent "weird," not "down." (During the incident: rt-sea's BGP had been down ~3 weeks and rt-sea2's VPS was hardware-dead.)

**Gap 2 — the anycast anchor is offshore.** The client-facing anycast resolver `10.127.255.53` is advertised and served **only** by rt-sea + rt-sea2. rt-ggz (on-prem, always-up) is *not* a provider. Lose both VPSes and the anycast `/32` is withdrawn entirely — there is no on-prem anchor.

## Goals & priorities

In strict priority order:

1. **Performance** — lowest, most consistent resolution latency for clients.
2. **Reliability** — hard rule: **no client's DNS may depend on a server that can vanish.** The VPSes are the unreliable elements; they must never be a hard dependency, only an enhancement.
3. **Privacy** — the adversary is the **on-path home ISP** (Comcast on `wan0`, T-Mobile on `wan1`), **not** Cloudflare. Encrypt DNS past the ISP; use root recursion where there is no on-path adversary.

## Current state

| Router | Blocky (`:53`) upstream | Unbound (`:5353`) method | Anycast `10.127.255.53` |
|---|---|---|---|
| rt-ggz | 3 unicast Unbounds, `parallel_best` | forward → **Cloudflare DoT** (`1.1.1.1@853`, `1.0.0.1@853`), `forward-first=true` (roots fallback) | **not** served/advertised |
| rt-sea | 3 unicast Unbounds, `parallel_best` | **root recursion** (no `forwardAddrs`) | served + advertised |
| rt-sea2 | 3 unicast Unbounds, `parallel_best` | **root recursion** | served + advertised |

- Clients (DHCP) get two resolvers: `10.127.0.1` (rt-ggz Blocky) primary, `10.127.255.53` (anycast) secondary.
- Internal zone `et42.net` is authoritative on rt-ggz (NSD/knot `:5354`); every Unbound conditional-forwards `et42.net` to it.

**Key finding:** the *resolution method* layer is already correct — home already uses Cloudflare DoT, the VPSes already recurse from roots. The bugs are entirely in the **Blocky-upstream** layer and the **anycast provider set**.

## Design

Three changes.

### 1. Decouple every resolver (fixes Gap 1)

Each router's Blocky forwards **only to its own local Unbound**:

```
rt-ggz  Blocky → rt-ggz  Unbound   (→ Cloudflare DoT, roots fallback)
rt-sea  Blocky → rt-sea  Unbound   (→ roots)
rt-sea2 Blocky → rt-sea2 Unbound   (→ roots)
```

A single local upstream means there is no `parallel_best` race and no cross-router dependency: no router's DNS can be affected by any other router or by a dead VPS. This is the core of the "avoid unreliable servers" rule. `strategy` becomes irrelevant with one upstream.

### 2. Anchor the anycast on-prem (fixes Gap 2)

**rt-ggz** (and rt-ggz2 when deployed) also **serves and advertises** `10.127.255.53` — Blocky binds the anycast address, and the `/32` is originated into BGP the same way rt-sea/rt-sea2 do it today. From the home network rt-ggz's advertisement is preferred (locally originated / lower cost), so home clients resolve on-prem; the VPSes continue to serve roaming/VPN clients and act as anycast backup. **Losing all VPSes leaves the anycast fully served on-prem.**

**Anycast health-gating:** each provider advertises the `/32` **only while it can actually resolve**, and withdraws it on failure. Without this, a "resolver dead (or WAN path dead) but router still up" state black-holes the anycast — the route stays advertised while nothing answers. With it, that state fails over to the next-nearest provider. The mechanism is specified in [Anycast health-gating mechanism](#anycast-health-gating-mechanism) below.

### 3. Resolution methods — keep as-is (already correct)

- **Home (rt-ggz, rt-ggz2): Cloudflare DoT, uniformly on any home WAN.** DoT on `:853` is encrypted (hides queries from Comcast/T-Mobile) **and** sails through T-Mobile's `:53` filter. Because home uses DoT regardless of which WAN is active, **no per-WAN switching, PBR, or dual-Unbound logic is needed** — the T-Mobile trap is avoided structurally. Keep `forward-first = true` so a (rare) Cloudflare-DoT outage degrades to root recursion rather than failing. (Caveat: on the T-Mobile WAN that roots fallback can't work — `:53` is filtered — but that is a double failure.)
- **VPS (rt-sea, rt-sea2): root recursion.** No on-path adversary there, so recurse from the roots for independence — "roots where possible."

Cloudflare seeing queries is acceptable per the threat model (adversary is the ISP, not Cloudflare).

### Final state

| Router | Blocky upstream | Recursion | Anycast provider | Egress privacy |
|---|---|---|---|---|
| rt-ggz | local Unbound only | Cloudflare DoT (roots fallback) | **YES (new)**, health-gated | encrypted past Comcast |
| rt-ggz2 (future) | local Unbound only | Cloudflare DoT (T-Mobile) | YES (new), health-gated | encrypted past T-Mobile |
| rt-sea / rt-sea2 | local Unbound only | roots | yes (existing), health-gated | independent |

### Client-facing resolver

Clients use the **anycast `10.127.255.53` as primary**, `10.127.0.1` (rt-ggz Blocky) as secondary. With rt-ggz as a health-gated anycast provider, the anycast resolves on-prem when healthy and fails over automatically (to a VPS) when rt-ggz's resolver is down — giving both local performance and automatic failover from a single VIP. Internal `et42.net` resolution is unchanged: every Unbound conditional-forwards it to rt-ggz's authoritative NSD.

## Anycast health-gating mechanism

Each anycast provider advertises its `/32` only while it can actually resolve, and withdraws it otherwise so anycast re-converges to the next-nearest provider. Because the `/32` rides `redistribute connected` from the `lo53` dummy interface, the entire control surface is `ip addr add/del 10.127.255.53/32 dev lo53` — no FRR interaction.

### Why a custom monitor (not pure systemd)

systemd natively expresses the **teardown** half but deliberately not the **recovery** half:

- `BindsTo = [ "blocky.service" "unbound.service" ]` + `After =` composes as **AND** — the unit is stopped the moment *either* daemon goes inactive. Correct teardown.
- But a unit stopped by `BindsTo` propagation is **not** auto-restarted when the dependency returns: the stop is an explicit propagated job, and `Restart=` only acts on *implicit* exits ([systemd#2824](https://github.com/systemd/systemd/issues/2824)). `Upholds=` is the only native recovery knob, and it composes as **OR** across two dependencies — so one daemon's `Upholds` fights the other daemon's `BindsTo` teardown when exactly one is down.

So a small poll loop owns the whole decision — teardown *and* recovery in one place, no directional conflict, and it can probe the actual data path (which unit-state can't).

### Health signal = liveness AND path

One poll every ~3–5 s computes `healthy = live AND path`:

- **`live`** — `systemctl is-active --quiet blocky && systemctl is-active --quiet unbound`. Catches daemon death/wedge. DNS-free.
- **`path`** — a direct query to the router's *real upstream*, testing the exact resource production needs (this is what catches a per-vantage-point path failure — e.g. rt-ggz→Comcast→Cloudflare broken while a VPS's path is fine):
  - **rt-ggz / rt-ggz2** (Cloudflare DoT): `kdig +tls +tls-hostname=cloudflare-dns.com +timeout=2 @1.1.1.1 cloudflare.com A` — try `@1.1.1.1` and `@1.0.0.1`; healthy if either returns `NOERROR`.
  - **rt-sea / rt-sea2** (roots): `kdig +timeout=2 @<root-ip> . NS` for a few root IPs; healthy if any returns `NOERROR`.

Probing the real upstream adds **no dependency** the router doesn't already require to function, and no node's health depends on another of our nodes (no self-hosted canary). `forward-first` on rt-ggz means the probe only trips on true WAN-wide breakage: if just the Cloudflare path is bad but general internet is fine, Unbound falls back to roots and still answers.

### Invariant: the probe resolves zero names

The gate must detect the **failed→live** transition while the local resolver is down and the anycast is withdrawn, so every probe target is a **literal IP** — no lookup, no circular dependency on the service being gated:

- `@1.1.1.1` / `@1.0.0.1` are literal. `+tls-hostname=cloudflare-dns.com` is SNI + certificate-name validation metadata, **not** a resolved name.
- Root IPs are extracted at runtime from the hints package, not hardcoded:
  ```bash
  awk '$4=="A"{print $5}' ${pkgs.dns-root-data}/root.hints | shuf | head -3
  ```
  This is a Nix-store **file read**, not a DNS query, so the bootstrap property holds. It is also a single source of truth that tracks IANA — e.g. b-root is `170.247.170.2` (renumbered 2023); a hardcoded list would silently go stale.

### Hysteresis and action

- **Hysteresis** (e.g. 3–4 consecutive fails over ~15–20 s → withdraw; 2–3 consecutive oks → restore) filters transient blips and normal deploy/reload restarts, so the `/32` never flaps the BGP mesh.
- **Action** on the debounced result: `ip addr add 10.127.255.53/32 dev lo53` (advertise) / `ip addr del …` (withdraw). Idempotent.

### Supporting config and caveats

- **`IPFreeBind = true`** on Blocky (`systemd.services.blocky.serviceConfig.IPFreeBind = true;`) so its listener bound to `10.127.255.53` survives the address coming and going. Required on every provider — all of them bind the anycast IP specifically.
- **Probe egress must match production.** rt-ggz policy-routes/marks DNS egress; bind the probe to the same source/fwmark, or it tests a divergent path.
- **Interpret rcode, not exit code.** `kdig` exits 0 even on `SERVFAIL`; grep the response header `status:` for `NOERROR`/`NXDOMAIN`.
- **Tool:** `kdig` (`knot-dnsutils`) — speaks both DoT (`+tls`) and plain `:53`.

### Floor

Clients keep the **never-gated unicast secondary** (`10.127.0.1`, rt-ggz.lo0). The gate decides *advertisement* only — it never touches real client resolution. So even a simultaneous global outage of every provider's probe target (withdrawing all `/32`s) leaves clients resolving via the unicast secondary.

Factor all of this into one `modules/router` option (e.g. `et42.router.anycastHealth`) consumed identically by rt-ggz, rt-ggz2, rt-sea, rt-sea2; the host's role selects the probe (CF-DoT vs roots).

## Evidence — performance of the chosen path

Measured from a home client, 30 cache-miss samples (random subdomains), warm caches:

| Path | RTT floor | miss median | mean | p90 | max |
|---|---|---|---|---|---|
| **rt-ggz → Cloudflare DoT (local)** | 0.4 ms | 15 ms | **12 ms** | **33 ms** | **36 ms** |
| rt-sea → roots (via tunnel) | 12.4 ms | 19 ms | 27 ms | 59 ms | 150 ms |
| rt-sea2 → roots (via tunnel) | 14.4 ms | 18 ms | 29 ms | 72 ms | 173 ms |

Forwarding home cache-misses through the VPS roots pays a structural ~12–14 ms Seattle round-trip on every query and has a much heavier tail (mean 2.3× higher, p90/max far worse). Local Cloudflare DoT is faster, more consistent, privacy-correct, and T-Mobile-safe. Confirms: **rt-ggz resolves locally via Cloudflare DoT; home DNS is never forwarded through the VPS.**

## Failure-mode walkthrough

| Scenario | Before | After |
|---|---|---|
| Both VPSes dead | intermittent client `SERVFAIL` | **no impact** — home resolves on-prem via rt-ggz DoT; anycast still served on-prem |
| rt-ggz `wan0` (Comcast) down | failover to T-Mobile | rt-ggz DoT still works over T-Mobile (`:853`); later rt-ggz2 owns T-Mobile |
| Cloudflare DoT outage | primary down | `forward-first` → root recursion (works on Comcast; degraded privacy that one case) |
| rt-ggz resolver dead, router up | anycast black-holes (no failover) | health-gating withdraws the anycast → fails over to a VPS |
| rt-ggz fully down | anycast gone (offshore only) | anycast → nearest VPS (roots); roaming/VPN clients covered |

## Components & representative changes

- **All routers, Blocky:** `upstream.servers = [ <local unbound only> ]`.
- **rt-ggz (+ rt-ggz2 later):** add anycast provider — bind Blocky to `globals.anycast.dns`, add the `lo53` dummy carrying the `/32`, originate it via `redistribute connected` (mirror rt-sea), firewall-allow DNS to the anycast IP.
- **Health-gate module** (`modules/router`, shared): the poll loop, role-based `kdig` probe, hysteresis, `ip addr add/del` on `lo53`, `IPFreeBind` on Blocky, and `${pkgs.dns-root-data}/root.hints` for root IPs. See [Anycast health-gating mechanism](#anycast-health-gating-mechanism).
- **rt-ggz / rt-ggz2 Unbound:** unchanged (Cloudflare DoT + `forward-first`).
- **rt-sea / rt-sea2 Unbound:** unchanged (roots).
- **Client resolver order:** anycast primary, rt-ggz loopback secondary (DHCP + `modules/router` `networking.nameservers`). The loopback secondary is the never-gated floor.
- Factor the shared anycast-provider + health-gate into one `modules/router` option so rt-ggz, rt-ggz2, rt-sea, rt-sea2 all consume one implementation; role selects the probe.

## Testing / verification

- **Latency regression:** re-run the cache-miss benchmark; confirm home resolution unchanged (~12 ms mean).
- **Failure simulation:** withdraw a VPS's anycast + stop its Blocky; query rt-ggz Blocky with 100 random names → **zero `SERVFAIL`**. Repeat with *both* VPSes down.
- **Anycast failover (daemon):** stop rt-ggz's Blocky; confirm the `/32` is withdrawn (`vtysh show ip route 10.127.255.53`) after the fail hysteresis, and clients fail over to a VPS.
- **Anycast failover (path):** black-hole rt-ggz's route to `1.1.1.1`/`1.0.0.1` (and roots) while leaving daemons up; confirm the probe's `path` check fails → `/32` withdrawn → failover. Restore the route → `/32` re-advertised after the ok hysteresis.
- **Bootstrap invariant:** with the local resolver stopped (anycast withdrawn), confirm the probe still runs and detects recovery — i.e. it resolves no names (targets are literal IPs / a store-file read).
- **Privacy check:** `tcpdump` `wan0` during a burst of lookups → only `:853` to Cloudflare; **no cleartext `:53`** to roots/authoritatives on the home WAN.

## Out of scope

- Deploying rt-ggz2 (design accommodates it: Cloudflare DoT on T-Mobile, anycast provider).
- rt-sea3 headend / client-VPN migration.
- Loopback re-IP migration (`10.127.x` → per-AS).
- Changing ad-block lists / client group policy.

## Open decisions

1. **Health-gating sequencing.** The mechanism is fully specified above; the only open call is whether to ship it with the two core changes (decouple + on-prem provider) or immediately after. The core changes fix the reported incident on their own; gating adds "resolver/path down but router up" failover.
2. **Client primary = anycast (recommended) vs rt-ggz loopback.** Anycast-primary gives single-VIP automatic failover once rt-ggz is a health-gated provider.
3. **Probe depth.** v1 probes the real upstream (CF-DoT reachability / root reachability). A stricter variant would test full recursion to an authoritative leaf; deferred unless upstream-reachable-but-recursion-broken proves to be a real failure mode.
