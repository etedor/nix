{ lib, config, ... }:

let
  cfg = config.et42.router.dns.nsd;

  # use a fixed serial number
  serialNumber = "2023120101";

  # helper function to generate SOA record for zone data
  generateSOA = domain: ''
    $ORIGIN ${domain}.
    $TTL 3600
    @ IN SOA ns.${domain}. admin.${domain}. (
      ${serialNumber} ; serial
      3600       ; refresh
      1800       ; retry
      604800     ; expire
      86400      ; minimum
    )
    @ IN NS ns.${domain}.
    ns IN A ${cfg.listenAddress}
  '';

  # generate A records for static hosts
  generateARecords =
    domain: hosts:
    lib.concatStringsSep "\n" (lib.mapAttrsToList (name: ip: "${name} IN A ${ip}") hosts);

  # generate PTR records for reverse zones
  generatePTRRecords =
    domain: reverseDomain: hosts:
    let
      # extract the network prefix from the reverse zone
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
            # for IPv4 addresses like 192.168.1.1 in zone 1.168.192.in-addr.arpa
            # we need the last octet for the PTR record
            lastOctet = lib.last (lib.splitString "." ip);
          in
          "${lastOctet} IN PTR ${hostname}.${domain}."
        )
        # filter hosts to only include those in the network prefix
        (lib.filterAttrs (hostname: ip: lib.hasPrefix networkPrefix ip) hosts)
    );

  # generate complete zone data
  generateZoneData = domain: hosts: ''
    ${generateSOA domain}
    ${generateARecords domain hosts}
  '';

  # generate reverse zone data
  generateReverseZoneData = domain: reverseDomain: hosts: ''
    ${generateSOA reverseDomain}
    ${generatePTRRecords domain reverseDomain hosts}
  '';

in
{
  options.et42.router.dns.nsd = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "whether to enable NSD authoritative DNS server";
    };

    listenAddress = lib.mkOption {
      type = lib.types.str;
      default = "127.0.0.1";
      description = "IP address on which NSD should listen";
    };

    listenPort = lib.mkOption {
      type = lib.types.port;
      default = 53;
      description = "port on which NSD should listen";
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
  };

  config = lib.mkIf cfg.enable {
    services.nsd = {
      enable = true;

      # basic configuration
      interfaces = [ cfg.listenAddress ];
      port = cfg.listenPort;

      # zone configuration
      zones = {
        # forward zone
        "${cfg.domainName}." = {
          data = generateZoneData cfg.domainName cfg.staticHosts;
        };
      }
      // lib.listToAttrs (
        # reverse zones
        map (reverseZone: {
          name = "${reverseZone}.";
          value = {
            data = generateReverseZoneData cfg.domainName reverseZone cfg.staticHosts;
          };
        }) cfg.reverseZones
      );
    };
  };
}
