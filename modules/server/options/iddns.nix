{
  lib,
  config,
  pkgs,
  globals,
  ...
}:

let
  cfg = config.et42.server.iddns;

  # auto-derive subdomains from nginx virtualHosts matching zone
  nginxSubdomains =
    let
      vhosts = builtins.attrNames config.services.nginx.virtualHosts;
      suffix = ".${cfg.zone}";
    in
    map (name: lib.removeSuffix suffix name)
      (builtins.filter (lib.hasSuffix suffix) vhosts);

  allSubdomains = lib.unique (nginxSubdomains ++ cfg.subdomains);

  # TXT record name for tracking managed subdomains (per-registrant IP)
  marker = "_managed-by-${builtins.replaceStrings ["."] ["-"] cfg.address}";

  script = pkgs.writeShellScript "iddns" ''
    set -uo pipefail

    KEY_FILE=${lib.escapeShellArg cfg.tsigKeyFile}
    ADDRESS=${lib.escapeShellArg cfg.address}
    ZONE=${lib.escapeShellArg cfg.zone}
    PORT=${toString cfg.port}
    TTL=${toString cfg.ttl}
    MARKER=${lib.escapeShellArg marker}
    CURRENT_SUBS=(${lib.concatMapStringsSep " " lib.escapeShellArg allSubdomains})
    SERVERS=(${lib.concatMapStringsSep " " lib.escapeShellArg cfg.servers})
    DIG=${pkgs.bind.dnsutils}/bin/dig
    NSUPDATE=${pkgs.bind.dnsutils}/bin/nsupdate

    for server in "''${SERVERS[@]}"; do
      # read previous managed subdomains from TXT manifest
      PREV_SUBS=()
      prev_raw=$("$DIG" +short TXT "$MARKER.$ZONE" @"$server" -p "$PORT" 2>/dev/null || true)
      if [ -n "$prev_raw" ]; then
        read -ra PREV_SUBS <<< "$(echo "$prev_raw" | tr -d '"')"
      fi

      # stale = previously managed but no longer current
      STALE=()
      for prev in "''${PREV_SUBS[@]}"; do
        found=0
        for cur in "''${CURRENT_SUBS[@]}"; do
          if [ "$prev" = "$cur" ]; then found=1; break; fi
        done
        [ "$found" = 0 ] && STALE+=("$prev")
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
        # update manifest TXT record
        echo "update delete $MARKER.$ZONE. TXT"
        echo "update add $MARKER.$ZONE. $TTL TXT \"''${CURRENT_SUBS[*]}\""
        echo "send"
      } | "$NSUPDATE" -k "$KEY_FILE" || true
    done
  '';
in
{
  options.et42.server.iddns = {
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
      default = globals.hosts.${config.networking.hostName}.ip;
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
    systemd.services.iddns = {
      description = "dynamic DNS registration via nsupdate";
      wants = [ "network-online.target" ];
      after = [ "network-online.target" ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = script;
      };
    };

    systemd.timers.iddns = {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnBootSec = "30s";
        OnUnitActiveSec = "1min";
      };
    };
  };
}
