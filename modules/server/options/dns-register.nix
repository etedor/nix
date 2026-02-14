{
  lib,
  config,
  pkgs,
  globals,
  ...
}:

let
  cfg = config.et42.server.dnsRegister;

  # auto-derive subdomains from nginx virtualHosts matching zone
  nginxSubdomains =
    let
      vhosts = builtins.attrNames config.services.nginx.virtualHosts;
      suffix = ".${cfg.zone}";
    in
    map (name: lib.removeSuffix suffix name)
      (builtins.filter (lib.hasSuffix suffix) vhosts);

  allSubdomains = lib.unique (nginxSubdomains ++ cfg.subdomains);

  script = pkgs.writeShellScript "dns-register" ''
    set -uo pipefail

    KEY_FILE=${lib.escapeShellArg cfg.tsigKeyFile}
    ADDRESS=${lib.escapeShellArg cfg.address}
    ZONE=${lib.escapeShellArg cfg.zone}
    PORT=${toString cfg.port}
    TTL=${toString cfg.ttl}
    CURRENT_SUBS=(${lib.concatMapStringsSep " " lib.escapeShellArg allSubdomains})
    SERVERS=(${lib.concatMapStringsSep " " lib.escapeShellArg cfg.servers})
    DIG=${pkgs.bind.dnsutils}/bin/dig
    NSUPDATE=${pkgs.bind.dnsutils}/bin/nsupdate

    for server in "''${SERVERS[@]}"; do
      # AXFR the zone, find A records matching our IP
      LIVE=()
      while IFS=$'\t' read -r name ttl class type rdata; do
        if [ "$type" = "A" ] && [ "$rdata" = "$ADDRESS" ]; then
          sub="''${name%."$ZONE".}"
          [ "$sub" != "$name" ] && LIVE+=("$sub")
        fi
      done < <("$DIG" AXFR @"$server" -p "$PORT" "$ZONE" +noall +answer 2>/dev/null || true)

      # stale = live records with our IP that aren't in current set
      STALE=()
      for live_sub in "''${LIVE[@]}"; do
        found=0
        for cur in "''${CURRENT_SUBS[@]}"; do
          if [ "$live_sub" = "$cur" ]; then found=1; break; fi
        done
        [ "$found" = 0 ] && STALE+=("$live_sub")
      done

      # send updates
      {
        echo "server $server $PORT"
        echo "zone $ZONE"
        for sub in "''${STALE[@]}"; do
          echo "update delete $sub.$ZONE. A $ADDRESS"
        done
        for sub in "''${CURRENT_SUBS[@]}"; do
          echo "update delete $sub.$ZONE. A $ADDRESS"
          echo "update add $sub.$ZONE. $TTL A $ADDRESS"
        done
        echo "send"
      } | "$NSUPDATE" -k "$KEY_FILE" || true
    done
  '';
in
{
  options.et42.server.dnsRegister = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "enable dynamic DNS registration via nsupdate";
    };

    zone = lib.mkOption {
      type = lib.types.str;
      description = "DNS zone to register in";
    };

    servers = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = lib.mapAttrsToList (_: r: r.interfaces.lo0) globals.routers;
      description = "router IPs to send updates to";
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 5354;
      description = "port for DNS update target";
    };

    address = lib.mkOption {
      type = lib.types.str;
      description = "IP address for A records";
    };

    tsigKeyFile = lib.mkOption {
      type = lib.types.path;
      description = "path to BIND-format TSIG key file";
    };

    ttl = lib.mkOption {
      type = lib.types.int;
      default = 300;
      description = "TTL for registered records";
    };

    subdomains = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "extra subdomains to register beyond nginx vhosts";
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.dns-register = {
      description = "register DNS records via nsupdate";
      wants = [ "network-online.target" ];
      after = [ "network-online.target" ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = script;
      };
    };

    systemd.timers.dns-register = {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnBootSec = "30s";
        OnUnitActiveSec = "1min";
      };
    };
  };
}
