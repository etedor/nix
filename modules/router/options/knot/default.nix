{
  lib,
  config,
  pkgs,
  globals,
  ...
}:

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
      300        ; minimum (negative cache TTL)
    )
    @ IN NS ns.${domain}.
    ns IN A ${cfg.listenAddress}
  '';

  # A records for static hosts
  generateARecords =
    domain: hosts:
    lib.concatStringsSep "\n" (lib.mapAttrsToList (name: ip: "${name} IN A ${ip}") hosts);

  # PTR records for a single zone's hosts within a reverse domain
  # returns a list of record strings
  generatePTRRecords =
    domain: reverseDomain: hosts:
    let
      reverseParts = lib.splitString "." (lib.removeSuffix ".in-addr.arpa" reverseDomain);
      networkPrefix = lib.concatStringsSep "." (lib.reverseList reverseParts);
      prefixLen = builtins.length reverseParts;
      hostPart =
        ip:
        let
          octets = lib.splitString "." ip;
        in
        lib.concatStringsSep "." (lib.reverseList (lib.drop prefixLen octets));
    in
    lib.mapAttrsToList (
      hostname: ip: "${hostPart ip} IN PTR ${hostname}.${domain}."
    ) (lib.filterAttrs (_: ip: lib.hasPrefix "${networkPrefix}." ip) hosts);

  # combined PTRs from all zones for a reverse domain
  generateAllPTRs =
    reverseDomain:
    lib.concatStringsSep "\n" (
      lib.concatLists (
        lib.mapAttrsToList (
          domain: zcfg: generatePTRRecords domain reverseDomain zcfg.staticHosts
        ) cfg.zones
      )
    );

  # complete forward zone data
  generateZoneData = domain: hosts: ''
    ${generateSOA domain}
    ${generateARecords domain hosts}
  '';

  # complete reverse zone data
  generateReverseZoneData = reverseDomain: ''
    ${generateSOA reverseDomain}
    ${generateAllPTRs reverseDomain}
  '';

  # zone files written to nix store
  forwardZoneFiles = lib.mapAttrsToList (domain: zcfg: {
    name = domain;
    file = pkgs.writeText "${domain}.zone" (generateZoneData domain zcfg.staticHosts);
  }) cfg.zones;

  reverseZoneFiles = map (rz: {
    name = rz;
    file = pkgs.writeText "${rz}.zone" (generateReverseZoneData rz);
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

    zones = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule {
        options.staticHosts = lib.mkOption {
          type = lib.types.attrsOf lib.types.str;
          default = { };
          description = "static host entries (hostname → IP)";
        };
      });
      default = lib.mapAttrs (_: hosts: { staticHosts = hosts; }) (
        import ./static-hosts.nix { inherit globals; }
      );
      description = "forward zones to serve, keyed by domain name";
    };

    reverseZones = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ "10.in-addr.arpa" ];
      description = "reverse DNS zones to serve";
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

        acl = lib.optionals (cfg.tsigKeyFile != null) [
          {
            id = "acl-update";
            address = cfg.updateAddresses;
            key = "xfer";
            action = "update";
          }
        ] ++ [
          {
            id = "acl-deny-xfr";
            action = "transfer";
            deny = true;
          }
        ];

        template = [
          {
            id = "default";
            storage = "/var/lib/knot/zones";
            journal-content = "all";
            zonefile-load = "difference-no-serial";
            serial-policy = "unixtime";
            acl = lib.optionals (cfg.tsigKeyFile != null) [ "acl-update" ] ++ [ "acl-deny-xfr" ];
          }
        ];

        zone =
          (lib.mapAttrsToList (domain: _: {
            inherit domain;
            file = "${domain}.zone";
          }) cfg.zones)
          ++ map (rz: {
            domain = rz;
            file = "${rz}.zone";
          }) cfg.reverseZones;
      };
    };

    # copy zone files from nix store to knot working directory
    systemd.services.knot.preStart =
      let
        installCmd = src: dst: "install -m 0640 -o knot -g knot ${src} /var/lib/knot/zones/${dst}";
      in
      lib.mkAfter ''
        mkdir -p /var/lib/knot/zones
        ${lib.concatStringsSep "\n" (map (fz: installCmd fz.file "${fz.name}.zone") forwardZoneFiles)}
        ${lib.concatStringsSep "\n" (map (rz: installCmd rz.file "${rz.name}.zone") reverseZoneFiles)}
      '';
  };
}
