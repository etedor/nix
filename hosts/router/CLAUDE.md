# network expansion schema

unified numbering schema for the 5-router mesh: rt-ggz, rt-ggz2, rt-sea, rt-sea2, rt-sea3.

## 1. design principles

### per-AS prefix ownership

each AS owns a /16 block. all addresses originated by a router come from its AS's prefix.

**rule: "high-side ASN owns the P2P, gets the lower address."**

for any P2P tunnel between two routers, the /31 is allocated from the higher ASN's /16 space. the high-side router gets the even (.0) address, the low-side router gets the odd (.1) address. this makes prefix ownership unambiguous — given any tunnel IP, you can immediately determine which AS owns it.

### loopbacks are shared infrastructure

loopbacks live in a shared 10.127.x.x range (not per-AS) because they are network-wide identifiers, not site-local resources. a single prefix-list covers all router-ids. see "future work" for planned migration to per-AS loopbacks.

### direct BGP peering over tunnel interfaces

BGP sessions peer on tunnel interface IPs, not loopbacks. rationale: in this topology, tunnel failure = data plane failure. losing a direct session is handled naturally by alternate paths through the mesh. loopback peering adds complexity (BFD, multihop) with no benefit.

### multi-hop conntrack+PBR for return routing

each router independently marks the ingress WG interface in conntrack (bits 3-0) and uses PBR to route return traffic back out the same interface. this preserves the original source IP end-to-end — vital for firewalling at the DNAT destination host. no SNAT/double NAT anywhere in the data path.

## 2. per-AS prefix allocation

| ASN   | Router  | Prefix        | Role                         |
|-------|---------|---------------|------------------------------|
| 65000 | rt-ggz  | 10.0.0.0/16   | on-prem primary router       |
| 65001 | rt-ggz2 | 10.1.0.0/16   | on-prem OOB/failover router  |
| 65100 | rt-sea  | 10.100.0.0/16 | VPS exit node                |
| 65101 | rt-sea2 | 10.101.0.0/16 | VPS exit node                |
| 65102 | rt-sea3 | 10.102.0.0/16 | VPS headend (DNAT + clients) |

the existing LAN subnets (10.0.2.0/24 through 10.0.32.0/24) fall within rt-ggz's 10.0.0.0/16 prefix, which is correct — rt-ggz is the on-prem primary gateway for those networks.

## 3. router summary

| Router  | ASN   | Loopback (current) | Loopback (future) | Prefix        | Role                              |
|---------|-------|--------------------|--------------------|---------------|-----------------------------------|
| rt-ggz  | 65000 | 10.127.0.1         | 10.0.127.1         | 10.0.0.0/16   | on-prem primary, wan0 (Docsis)    |
| rt-ggz2 | 65001 | 10.127.1.1         | 10.1.127.1         | 10.1.0.0/16   | on-prem OOB, wan1 (LTE)           |
| rt-sea  | 65100 | 10.127.100.1       | 10.100.127.1       | 10.100.0.0/16 | VPS exit node                     |
| rt-sea2 | 65101 | 10.127.101.1       | 10.101.127.1       | 10.101.0.0/16 | VPS exit node                     |
| rt-sea3 | 65102 | 10.127.102.1       | 10.102.127.1       | 10.102.0.0/16 | VPS headend, DNAT, client VPN     |

## 4. tunnel matrix

8 tunnels total. P2P /31s allocated from the high-side ASN's prefix.

| Tunnel              | Owner (high ASN)   | /31 Block       | High-side IP (.0) | Low-side IP (.1) | Type     |
|---------------------|--------------------|-----------------|--------------------|-------------------|----------|
| rt-sea ↔ rt-ggz     | rt-sea (65100)     | 10.100.0.0/31   | 10.100.0.0         | 10.100.0.1        | WG (existing) |
| rt-sea ↔ rt-ggz2    | rt-sea (65100)     | 10.100.0.2/31   | 10.100.0.2         | 10.100.0.3        | WG       |
| rt-sea2 ↔ rt-ggz    | rt-sea2 (65101)    | 10.101.0.0/31   | 10.101.0.0         | 10.101.0.1        | WG       |
| rt-sea2 ↔ rt-ggz2   | rt-sea2 (65101)    | 10.101.0.2/31   | 10.101.0.2         | 10.101.0.3        | WG       |
| rt-sea2 ↔ rt-sea    | rt-sea2 (65101)    | 10.101.0.4/31   | 10.101.0.4         | 10.101.0.5        | WG       |
| rt-sea3 ↔ rt-sea    | rt-sea3 (65102)    | 10.102.0.0/31   | 10.102.0.0         | 10.102.0.1        | WG       |
| rt-sea3 ↔ rt-sea2   | rt-sea3 (65102)    | 10.102.0.2/31   | 10.102.0.2         | 10.102.0.3        | WG       |
| rt-ggz2 ↔ rt-ggz    | rt-ggz2 (65001)    | 10.1.0.0/31     | 10.1.0.0           | 10.1.0.1          | Ethernet |

address space segmentation:
- 10.100.0.x — rt-sea's P2P tunnels (to on-prem)
- 10.101.0.x — rt-sea2's P2P tunnels (to on-prem + rt-sea)
- 10.102.0.x — rt-sea3's P2P tunnels (inter-VPS mesh)
- 10.1.0.x — rt-ggz2's direct link

## 5. WG interface map

interfaces ordered by remote peer ASN ascending. port = 51820 + N.

### rt-ggz (AS65000)

| Interface | Remote    | Port  | Local IP    | Remote IP   |
|-----------|-----------|-------|-------------|-------------|
| wg0       | rt-sea    | 51820 | 10.100.0.1  | 10.100.0.0  |
| wg1       | rt-sea2   | 51821 | 10.101.0.1  | 10.101.0.0  |

### rt-ggz2 (AS65001)

| Interface | Remote    | Port  | Local IP    | Remote IP   |
|-----------|-----------|-------|-------------|-------------|
| wg0       | rt-sea    | 51820 | 10.100.0.3  | 10.100.0.2  |
| wg1       | rt-sea2   | 51821 | 10.101.0.3  | 10.101.0.2  |

direct link (not WG):

| Interface | Remote    | Local IP   | Remote IP  |
|-----------|-----------|------------|------------|
| link0     | rt-ggz    | 10.1.0.0   | 10.1.0.1   |

### rt-sea (AS65100)

| Interface | Remote    | Port  | Local IP    | Remote IP   |
|-----------|-----------|-------|-------------|-------------|
| wg0       | rt-ggz    | 51820 | 10.100.0.0  | 10.100.0.1  |
| wg1       | rt-ggz2   | 51821 | 10.100.0.2  | 10.100.0.3  |
| wg2       | rt-sea2   | 51822 | 10.101.0.5  | 10.101.0.4  |
| wg3       | rt-sea3   | 51823 | 10.102.0.1  | 10.102.0.0  |

### rt-sea2 (AS65101)

| Interface | Remote    | Port  | Local IP    | Remote IP   |
|-----------|-----------|-------|-------------|-------------|
| wg0       | rt-ggz    | 51820 | 10.101.0.0  | 10.101.0.1  |
| wg1       | rt-ggz2   | 51821 | 10.101.0.2  | 10.101.0.3  |
| wg2       | rt-sea    | 51822 | 10.101.0.4  | 10.101.0.5  |
| wg3       | rt-sea3   | 51823 | 10.102.0.3  | 10.102.0.2  |

### rt-sea3 (AS65102)

| Interface | Remote    | Port  | Local IP    | Remote IP   |
|-----------|-----------|-------|-------------|-------------|
| wg0       | rt-sea    | 51820 | 10.102.0.0  | 10.102.0.1  |
| wg1       | rt-sea2   | 51821 | 10.102.0.2  | 10.102.0.3  |

client VPN interfaces (on rt-sea3 only):

| Interface | Port  | Subnet          | Purpose |
|-----------|-------|-----------------|---------|
| wg10      | 51830 | 10.102.10.0/24  | admin   |
| wg11      | 51831 | 10.102.11.0/24  | family  |

## 6. BGP peering table

all sessions use direct tunnel IPs (not loopbacks).

### rt-ggz (AS65000)

| Neighbor     | Remote ASN | Via Interface | Description |
|-------------|------------|---------------|-------------|
| 10.100.0.0  | 65100      | wg0           | rt-sea      |
| 10.101.0.0  | 65101      | wg1           | rt-sea2     |
| 10.1.0.0    | 65001      | link0         | rt-ggz2     |

### rt-ggz2 (AS65001)

| Neighbor     | Remote ASN | Via Interface | Description |
|-------------|------------|---------------|-------------|
| 10.100.0.2  | 65100      | wg0           | rt-sea      |
| 10.101.0.2  | 65101      | wg1           | rt-sea2     |
| 10.1.0.1    | 65000      | link0         | rt-ggz      |

### rt-sea (AS65100)

| Neighbor     | Remote ASN | Via Interface | Description |
|-------------|------------|---------------|-------------|
| 10.100.0.1  | 65000      | wg0           | rt-ggz      |
| 10.100.0.3  | 65001      | wg1           | rt-ggz2     |
| 10.101.0.4  | 65101      | wg2           | rt-sea2     |
| 10.102.0.0  | 65102      | wg3           | rt-sea3     |

### rt-sea2 (AS65101)

| Neighbor     | Remote ASN | Via Interface | Description |
|-------------|------------|---------------|-------------|
| 10.101.0.1  | 65000      | wg0           | rt-ggz      |
| 10.101.0.3  | 65001      | wg1           | rt-ggz2     |
| 10.101.0.5  | 65100      | wg2           | rt-sea      |
| 10.102.0.2  | 65102      | wg3           | rt-sea3     |

### rt-sea3 (AS65102)

| Neighbor     | Remote ASN | Via Interface | Description |
|-------------|------------|---------------|-------------|
| 10.102.0.1  | 65100      | wg0           | rt-sea      |
| 10.102.0.3  | 65101      | wg1           | rt-sea2     |

rt-sea3 has NO direct tunnels to on-prem routers. it reaches on-prem networks via rt-sea or rt-sea2.

## 7. conntrack mark assignments

mark layout (all routers): bits 31-26 = DSCP value, bit 24 = DSCP valid flag, bits 23-4 = reserved, bits 3-0 = PBR tunnel ID.

PBR tunnel IDs are per-router local scope. mark N = wg(N-1).

### rt-ggz

| Mark (bits 3-0) | Interface | Remote  |
|-----------------|-----------|---------|
| 0               | (none)    | normal routing |
| 1               | wg0       | rt-sea  |
| 2               | wg1       | rt-sea2 |

### rt-ggz2

| Mark (bits 3-0) | Interface | Remote  |
|-----------------|-----------|---------|
| 0               | (none)    | normal routing |
| 1               | wg0       | rt-sea  |
| 2               | wg1       | rt-sea2 |

### rt-sea

| Mark (bits 3-0) | Interface | Remote  |
|-----------------|-----------|---------|
| 0               | (none)    | normal routing |
| 1               | wg0       | rt-ggz  |
| 2               | wg1       | rt-ggz2 |
| 3               | wg2       | rt-sea2 |
| 4               | wg3       | rt-sea3 |

### rt-sea2

| Mark (bits 3-0) | Interface | Remote  |
|-----------------|-----------|---------|
| 0               | (none)    | normal routing |
| 1               | wg0       | rt-ggz  |
| 2               | wg1       | rt-ggz2 |
| 3               | wg2       | rt-sea  |
| 4               | wg3       | rt-sea3 |

### rt-sea3

| Mark (bits 3-0) | Interface | Remote  |
|-----------------|-----------|---------|
| 0               | (none)    | normal routing |
| 1               | wg0       | rt-sea  |
| 2               | wg1       | rt-sea2 |

## 8. PBR nexthop groups and maps

each router defines a nexthop group per WG tunnel and a PBR map that matches conntrack marks to the correct nexthop group.

### rt-ggz

```
nexthop-group VPS-WG0
  nexthop 10.100.0.0        # rt-sea via wg0

nexthop-group VPS-WG1
  nexthop 10.101.0.0        # rt-sea2 via wg1

pbr-map VPS-RETURN seq 10
  match mark 1
  set nexthop-group VPS-WG0

pbr-map VPS-RETURN seq 20
  match mark 2
  set nexthop-group VPS-WG1

interface vlan4
  pbr-policy VPS-RETURN
```

nftables mangle rules:
- **prerouting:** restore conntrack mark to fwmark for packets with non-RFC1918 destination and ct mark bits 3-0 != 0
- **forward:** on new connections arriving from each WG interface with non-RFC1918 source, set ct mark bits 3-0 to the tunnel ID

### rt-ggz2

```
nexthop-group VPS-WG0
  nexthop 10.100.0.2        # rt-sea via wg0

nexthop-group VPS-WG1
  nexthop 10.101.0.2        # rt-sea2 via wg1

pbr-map VPS-RETURN seq 10
  match mark 1
  set nexthop-group VPS-WG0

pbr-map VPS-RETURN seq 20
  match mark 2
  set nexthop-group VPS-WG1
```

(PBR policy applied to interfaces as needed — rt-ggz2 primarily serves OOB/failover.)

### rt-sea

```
nexthop-group ONPREM-WG0
  nexthop 10.100.0.1        # rt-ggz via wg0

nexthop-group ONPREM-WG1
  nexthop 10.100.0.3        # rt-ggz2 via wg1

nexthop-group VPS-WG2
  nexthop 10.101.0.4        # rt-sea2 via wg2

nexthop-group VPS-WG3
  nexthop 10.102.0.0        # rt-sea3 via wg3

pbr-map RETURN seq 10
  match mark 1
  set nexthop-group ONPREM-WG0

pbr-map RETURN seq 20
  match mark 2
  set nexthop-group ONPREM-WG1

pbr-map RETURN seq 30
  match mark 3
  set nexthop-group VPS-WG2

pbr-map RETURN seq 40
  match mark 4
  set nexthop-group VPS-WG3
```

### rt-sea2

```
nexthop-group ONPREM-WG0
  nexthop 10.101.0.1        # rt-ggz via wg0

nexthop-group ONPREM-WG1
  nexthop 10.101.0.3        # rt-ggz2 via wg1

nexthop-group VPS-WG2
  nexthop 10.101.0.5        # rt-sea via wg2

nexthop-group VPS-WG3
  nexthop 10.102.0.2        # rt-sea3 via wg3

pbr-map RETURN seq 10
  match mark 1
  set nexthop-group ONPREM-WG0

pbr-map RETURN seq 20
  match mark 2
  set nexthop-group ONPREM-WG1

pbr-map RETURN seq 30
  match mark 3
  set nexthop-group VPS-WG2

pbr-map RETURN seq 40
  match mark 4
  set nexthop-group VPS-WG3
```

### rt-sea3

```
nexthop-group VPS-WG0
  nexthop 10.102.0.1        # rt-sea via wg0

nexthop-group VPS-WG1
  nexthop 10.102.0.3        # rt-sea2 via wg1

pbr-map RETURN seq 10
  match mark 1
  set nexthop-group VPS-WG0

pbr-map RETURN seq 20
  match mark 2
  set nexthop-group VPS-WG1
```

## 9. client VPN subnets

client VPN interfaces migrate from rt-sea to rt-sea3. subnets move to rt-sea3's AS prefix (10.102.x.x).

| Interface | Router  | Subnet          | Gateway      | Purpose |
|-----------|---------|-----------------|--------------|---------|
| wg10      | rt-sea3 | 10.102.10.0/24  | 10.102.10.1  | admin VPN clients |
| wg11      | rt-sea3 | 10.102.11.0/24  | 10.102.11.1  | family VPN clients |

client IP assignments:

| Client    | Interface | IP Address    | Previous (rt-sea) |
|-----------|-----------|---------------|--------------------|
| pine      | wg10      | 10.102.10.11  | 10.100.10.11       |
| carbon    | wg10      | 10.102.10.12  | 10.100.10.12       |
| rt-travel | wg11      | 10.102.11.11  | 10.100.11.11       |
| jade      | wg11      | 10.102.11.34  | 10.100.11.34       |

previous (rt-sea): wg10 was 10.100.10.0/24, wg11 was 10.100.11.0/24. clients will need updated configs pointing to rt-sea3's public IP and new subnets.

## 10. DNAT rules

### rt-sea3 (headend)

rt-sea3 is the DNAT headend. external traffic arrives at rt-sea3's public IP, gets DNAT'd to on-prem hosts (e.g., duke at 10.0.4.32).

rt-sea3 has no direct WG tunnel to on-prem routers. traffic reaches on-prem via a multi-hop conntrack+PBR chain through rt-sea or rt-sea2. **no double NAT** — the original source IP is preserved end-to-end.

### rt-sea (transitional DNAT)

rt-sea continues to handle DNAT for its own public IP during the migration period. it has a direct tunnel to rt-ggz, so the path is single-hop. **transitional** — DNAT rules will be removed from rt-sea once rt-sea3 is fully operational and DNS/port forwarding is migrated.

## 11. NAT/masquerade rules

### WAN egress masquerade

only on-prem routers masquerade RFC1918 traffic on their WAN interfaces. VPS routers do **not** masquerade — VPN clients are split-tunnel (only route to home network, not internet exit via VPS).

| Router  | Interface | Rule                                  |
|---------|-----------|---------------------------------------|
| rt-ggz  | wan0      | RFC1918 source → masquerade on wan0   |
| rt-ggz2 | wan1      | RFC1918 source → masquerade on wan1   |

### failover masquerade (rt-ggz → rt-ggz2)

when rt-ggz's wan0 goes down, rt-ggz routes traffic via link0 to rt-ggz2. rt-ggz2 masquerades all rt-ggz traffic on wan1 (LTE).

- rt-ggz2's existing masquerade rule (RFC1918 on wan1) covers rt-ggz's subnets automatically
- vnstat on rt-ggz2 sees total wan1 usage for datacap monitoring
- per-source granularity available via nftables counters per source subnet in NAT postrouting

### conntrack zones (rt-ggz)

rt-ggz uses conntrack zones to isolate NAT state per WAN:
- zone 1: wan0 traffic
- zone 2: wan1 traffic (future: may be removed since wan1 moves to rt-ggz2)

## 12. traffic flow diagrams

### DNAT ingress via rt-sea (single hop, existing pattern)

```
internet → rt-sea (ens3)
           │ DNAT: dst → 10.0.4.32 (duke)
           │ ct mark wg0 ingress on rt-ggz side
           ▼
         [wg0] ─── WG tunnel ─── [wg0] rt-ggz
                                        │ PBR: vlan4 → VPS-RETURN
                                        ▼
                                    [vlan4] → duke (10.0.4.32)

return: duke → rt-ggz [vlan4]
              │ ct mark = 1 (wg0)
              │ PBR: match mark 1 → nexthop-group VPS-WG0
              ▼
            [wg0] ─── WG tunnel ─── [wg0] rt-sea
                                          │ conntrack reverse DNAT
                                          ▼
                                      [ens3] → internet
```

### DNAT ingress via rt-sea3 (multi-hop, new pattern)

```
internet → rt-sea3 (ens3)
           │ DNAT: dst → 10.0.4.32 (duke)
           │ route to 10.0.4.0/24 via BGP → rt-sea or rt-sea2
           ▼
         [wg0] ─── WG tunnel ─── [wg3] rt-sea
                                        │ ct mark bits 3-0 = 4 (wg3, from rt-sea3)
                                        │ route to 10.0.4.0/24 via BGP → rt-ggz
                                        ▼
                                      [wg0] ─── WG tunnel ─── [wg0] rt-ggz
                                                                      │ ct mark bits 3-0 = 1 (wg0, from rt-sea)
                                                                      │ forward to duke
                                                                      ▼
                                                                  [vlan4] → duke (10.0.4.32)

return: duke → rt-ggz [vlan4]
              │ ct mark = 1 (wg0)
              │ PBR: match mark 1 → VPS-WG0 (10.100.0.0 = rt-sea)
              ▼
            [wg0] ─── WG tunnel ─── [wg0] rt-sea
                                          │ ct mark = 4 (wg3)
                                          │ PBR: match mark 4 → VPS-WG3 (10.102.0.0 = rt-sea3)
                                          ▼
                                        [wg3] ─── WG tunnel ─── [wg0] rt-sea3
                                                                        │ conntrack reverse DNAT
                                                                        ▼
                                                                    [ens3] → internet
```

source IP is preserved at every hop. duke sees the real client IP.

### failover path (rt-ggz wan0 down)

```
rt-ggz [vlan4] ← duke reply
  │ wan0 DOWN, default route via link0 → rt-ggz2
  ▼
[link0] ─── Ethernet ─── [link0] rt-ggz2
                                  │ masquerade on wan1
                                  ▼
                              [wan1 (LTE)] → internet
```

## 13. future work

### loopback migration to per-AS addressing

current loopbacks (10.127.x.x) will migrate to per-AS addresses:

| Router  | Current      | Target       |
|---------|-------------|--------------|
| rt-ggz  | 10.127.0.1   | 10.0.127.1   |
| rt-ggz2 | 10.127.1.1   | 10.1.127.1   |
| rt-sea  | 10.127.100.1 | 10.100.127.1 |
| rt-sea2 | 10.127.101.1 | 10.101.127.1 |
| rt-sea3 | 10.127.102.1 | 10.102.127.1 |

migration requires updating: BGP router-id, DNS records, firewall rules, monitoring targets, and any config referencing loopback IPs.

### management network re-IP

192.168.0.0/24 (mgmt) to be redesigned as a proper management network with rt-ggz2 as gateway. scope and addressing TBD.

### rt-ggz wan1 removal

rt-ggz loses wan1 (LTE moves to rt-ggz2). wan1-related config to be removed:
- wan1 interface and link config
- CAKE QoS for wan1
- failmon-wan1 and usemon-wan1 services
- conntrack zone 2
- masquerade rule for wan1

### client VPN migration

wg10/wg11 clients need updated configs:
- new endpoint: rt-sea3 public IP
- new subnet: 10.102.10.0/24 (admin), 10.102.11.0/24 (family)
- new keys (rt-sea3 WG keypairs)

## globals.nix updates

```nix
routers = {
  rt-ggz = {
    localAs = 65000;
    interfaces = {
      lo0 = "10.127.0.1";
      wg0 = "10.100.0.1";   # P2P to rt-sea
      wg1 = "10.101.0.1";   # P2P to rt-sea2
      link0 = "10.1.0.1";   # direct link to rt-ggz2
    };
  };
  rt-ggz2 = {
    localAs = 65001;
    interfaces = {
      lo0 = "10.127.1.1";
      wg0 = "10.100.0.3";   # P2P to rt-sea
      wg1 = "10.101.0.3";   # P2P to rt-sea2
      link0 = "10.1.0.0";   # direct link to rt-ggz
    };
  };
  rt-sea = {
    extIntf = "ens3";
    localAs = 65100;
    interfaces = {
      ens3 = "66.42.69.91";
      lo0 = "10.127.100.1";
      wg0 = "10.100.0.0";   # P2P to rt-ggz
      wg1 = "10.100.0.2";   # P2P to rt-ggz2
      wg2 = "10.101.0.5";   # P2P to rt-sea2
      wg3 = "10.102.0.1";   # P2P to rt-sea3
    };
  };
  rt-sea2 = {
    extIntf = "ens3";
    localAs = 65101;
    interfaces = {
      ens3 = "<rt-sea2-pub>";
      lo0 = "10.127.101.1";
      wg0 = "10.101.0.0";   # P2P to rt-ggz
      wg1 = "10.101.0.2";   # P2P to rt-ggz2
      wg2 = "10.101.0.4";   # P2P to rt-sea
      wg3 = "10.102.0.3";   # P2P to rt-sea3
    };
  };
  rt-sea3 = {
    extIntf = "ens3";
    localAs = 65102;
    interfaces = {
      ens3 = "<rt-sea3-pub>";
      lo0 = "10.127.102.1";
      wg0 = "10.102.0.0";   # P2P to rt-sea
      wg1 = "10.102.0.2";   # P2P to rt-sea2
      wg10 = "10.102.10.1"; # admin VPN
      wg11 = "10.102.11.1"; # family VPN
    };
  };
};
```
