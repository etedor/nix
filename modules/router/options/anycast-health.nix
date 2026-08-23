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
      pkgs.knot-dns
      pkgs.iproute2
      pkgs.systemd
      pkgs.gawk
      pkgs.coreutils
    ];
    text = ''
      # no -e: the poll loop must survive a single command's nonzero exit; risky commands guard themselves
      set -uo pipefail

      ADDR="${cfg.address}"
      DEV="${cfg.device}"
      MODE="${cfg.probe}"
      INTERVAL=${toString cfg.interval}
      FAIL_THRESHOLD=${toString cfg.failThreshold}
      OK_THRESHOLD=${toString cfg.okThreshold}

      have_addr() { ip -4 addr show dev "$DEV" 2>/dev/null | grep -qF "$ADDR/32"; }
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
        ips=$(awk '$3=="A"{print $4}' "${rootHints}" | shuf | head -3)
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
