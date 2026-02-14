{ lib, config, pkgs, globals, ... }:

let
  cfg = config.et42.router.dns.knot;

  # SOA record for zone data
  generateSOA = domain: ''
    $ORIGIN ${domain}.
    $TTL 3600
    @ IN SOA ns.${domain}. admin.${domain}. (
      0          ; serial (auto-managed by knot)
      3600       ; refresh
      1800       ; retry
      604800     ; expire
      86400      ; minimum
    )
    @ IN NS ns.${domain}.
    ns IN A ${cfg.listenAddress}
  '';

  # A records for static hosts
  generateARecords =
    domain: hosts:
    lib.concatStringsSep "\n" (lib.mapAttrsToList (name: ip: "${name} IN A ${ip}") hosts);

  # PTR records for reverse zones
  generatePTRRecords =
    domain: reverseDomain: hosts:
    let
      # extract network prefix from reverse zone
      # e.g., "10.168.192.in-addr.arpa" -> "192.168.10"
      networkPrefix =
        if lib.hasSuffix "in-addr.arpa" reverseDomain then
          let
            parts = lib.splitString "." (lib.removeSuffix ".in-addr.arpa" reverseDomain);
          in
          lib.concatStringsSep "." (lib.reverseList parts)
        else
          "";
    in
    lib.concatStringsSep "\n" (
      lib.mapAttrsToList
        (
          hostname: ip:
          let
            lastOctet = lib.last (lib.splitString "." ip);
          in
          "${lastOctet} IN PTR ${hostname}.${domain}."
        )
        (lib.filterAttrs (_: ip: lib.hasPrefix networkPrefix ip) hosts)
    );

  # complete forward zone data
  generateZoneData = domain: hosts: ''
    ${generateSOA domain}
    ${generateARecords domain hosts}
  '';

  # complete reverse zone data
  generateReverseZoneData = domain: reverseDomain: hosts: ''
    ${generateSOA reverseDomain}
    ${generatePTRRecords domain reverseDomain hosts}
  '';

  # zone files written to nix store
  forwardZoneFile = pkgs.writeText "${cfg.domainName}.zone" (
    generateZoneData cfg.domainName cfg.staticHosts
  );

  reverseZoneFiles = map (rz: {
    name = rz;
    file = pkgs.writeText "${rz}.zone" (
      generateReverseZoneData cfg.domainName rz cfg.staticHosts
    );
  }) cfg.reverseZones;

in
{
  options.et42.router.dns.knot = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "whether to enable Knot authoritative DNS server";
    };

    listenAddress = lib.mkOption {
      type = lib.types.str;
      default = "127.0.0.1";
      description = "IP address on which Knot should listen";
    };

    listenPort = lib.mkOption {
      type = lib.types.port;
      default = 5354;
      description = "port on which Knot should listen";
    };

    domainName = lib.mkOption {
      type = lib.types.str;
      description = "primary DNS zone to serve";
    };

    reverseZones = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "reverse DNS zones to serve (e.g., '1.168.192.in-addr.arpa')";
    };

    staticHosts = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = { };
      description = "static host entries to add to the zone (hostname -> IP)";
    };

    tsigKeyFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = "agenix-decrypted Knot-format TSIG key file";
    };

    updateAddresses = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = lib.mapAttrsToList (_: h: h.ip) (lib.filterAttrs (_: h: h.server or false) globals.hosts);
      description = "IPs allowed to send RFC 2136 updates";
    };
  };

  config = lib.mkIf cfg.enable {
    services.knot = {
      enable = true;
      keyFiles = lib.optional (cfg.tsigKeyFile != null) cfg.tsigKeyFile;
      settings = {
        server.listen = [ "${cfg.listenAddress}@${toString cfg.listenPort}" ];

        acl = lib.optional (cfg.tsigKeyFile != null) {
          id = "acl-update";
          address = cfg.updateAddresses;
          key = "xfer";
          action = "update";
        };

        template = [
          {
            id = "default";
            storage = "/var/lib/knot/zones";
            journal-content = "all";
            zonefile-load = "difference-no-serial";
            serial-policy = "unixtime";
            acl = lib.optional (cfg.tsigKeyFile != null) "acl-update";
          }
        ];

        zone =
          [
            {
              domain = cfg.domainName;
              file = "${cfg.domainName}.zone";
            }
          ]
          ++ map (rz: {
            domain = rz;
            file = "${rz}.zone";
          }) cfg.reverseZones;
      };
    };

    # copy zone files from nix store to knot working directory
    systemd.services.knot.preStart =
      let
        installCmd = src: dst: "install -m 0644 -o knot -g knot ${src} /var/lib/knot/zones/${dst}";
      in
      lib.mkAfter ''
        mkdir -p /var/lib/knot/zones
        ${installCmd forwardZoneFile "${cfg.domainName}.zone"}
        ${lib.concatStringsSep "\n" (
          map (rz: installCmd rz.file "${rz.name}.zone") reverseZoneFiles
        )}
      '';
  };
}
