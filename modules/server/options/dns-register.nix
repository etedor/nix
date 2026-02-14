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

  # nsupdate batch commands per subdomain (static, built at eval time)
  updateLines = lib.concatMapStrings (sub: ''
    update delete ${sub}.${cfg.zone}. A
    update add ${sub}.${cfg.zone}. ${toString cfg.ttl} A ${cfg.address}
  '') allSubdomains;

  script = pkgs.writeShellScript "dns-register" ''
    set -uo pipefail

    KEY_FILE=${lib.escapeShellArg cfg.tsigKeyFile}
    SERVERS=(${lib.concatMapStringsSep " " lib.escapeShellArg cfg.servers})

    for server in "''${SERVERS[@]}"; do
      ${pkgs.bind.dnsutils}/bin/nsupdate -k "$KEY_FILE" <<NSUPDATE || true
    server $server ${toString cfg.port}
    zone ${cfg.zone}
    ${updateLines}send
    NSUPDATE
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
