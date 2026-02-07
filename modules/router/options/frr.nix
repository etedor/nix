{
  config,
  globals,
  lib,
  ...
}:

let
  concatNL = lines: lib.concatStringsSep "\n" lines;

  mkRoute =
    attrs:
    let
      network = attrs.network;
      viaIface = attrs.iface or "";
      viaGateway = attrs.gateway or null;
      dist = if attrs.blackhole or false then 250 else attrs.distance or null;
      isBH = attrs.blackhole or false;
      table = attrs.table or null;
      via =
        if isBH then
          "blackhole"
        else if viaGateway != null then
          viaGateway
        else
          viaIface;
      distPart = if dist != null then " " + toString dist else "";
      tablePart = if table != null then " table " + toString table else "";
    in
    "ip route ${network} ${via}${distPart}${tablePart}";

  mkPrefixList =
    attrs:
    let
      name = attrs.name;
      seq = attrs.seq;
      action = attrs.action;
      prefix = attrs.prefix;
      ge = attrs.ge or null;
      le = attrs.le or null;
      gePart = if ge != null then " ge ${toString ge}" else "";
      lePart = if le != null then " le ${toString le}" else "";
    in
    "ip prefix-list ${name} seq ${toString seq} ${action} ${prefix}${gePart}${lePart}";

  mkRouteMap =
    attrs:
    let
      name = attrs.name;
      seq = attrs.seq;
      action = attrs.action;
      matches = attrs.match or [ ];
      sets = attrs.set or [ ];
      matchLines = lib.map (m: " match ${m}") matches;
      setLines = lib.map (s: " set ${s}") sets;
      bodyLines = matchLines ++ setLines;
      body = if bodyLines != [ ] then concatNL bodyLines else "";
    in
    concatNL (
      [ "route-map ${name} ${action} ${toString seq}" ]
      ++ (if body != "" then [ body ] else [ ])
      ++ [ "exit" ]
    );

  rfc1918BlackholeRoutes = [
    { network = "10.0.0.0/8"; iface = "blackhole"; }
    { network = "172.16.0.0/12"; iface = "blackhole"; }
    { network = "192.168.0.0/16"; iface = "blackhole"; }
  ];

  rfc1918PrefixListEntries = [
    { name = "PL-RFC1918_V4"; seq = 5; action = "permit"; prefix = "10.0.0.0/8"; ge = 8; le = 32; }
    { name = "PL-RFC1918_V4"; seq = 10; action = "permit"; prefix = "172.16.0.0/12"; ge = 12; le = 32; }
    { name = "PL-RFC1918_V4"; seq = 15; action = "permit"; prefix = "192.168.0.0/16"; ge = 16; le = 32; }
  ];

  rfc1918RouteMapEntries = [
    { name = "RM-RFC1918_V4"; seq = 10; action = "permit"; match = [ "ip address prefix-list PL-RFC1918_V4" ]; }
  ];

  mkNeighbor =
    nb:
    let
      ip = nb.ip;
      remoteAs = nb.remoteAs;
      softReconfig = nb.softReconfigInbound or true;
      bfd = nb.bfd or true;
      timers = nb.timers or { keepalive = 10; hold = 30; };
    in
    [ " neighbor ${ip} remote-as ${toString remoteAs}" ]
    ++ (if timers != null then [ " neighbor ${ip} timers ${toString timers.keepalive} ${toString timers.hold}" ] else [ ])
    ++ (if bfd then [ " neighbor ${ip} bfd" ] else [ ])
    ++ (if softReconfig then [ " neighbor ${ip} soft-reconfiguration inbound" ] else [ ]);

  mkAddressFamilyNeighbor =
    nb:
    let
      ip = nb.ip;
      inMap = nb.routeMapIn;
      outMap = nb.routeMapOut;
      inLine = if inMap != null then " neighbor ${ip} route-map ${inMap} in" else "";
      outLine = if outMap != null then " neighbor ${ip} route-map ${outMap} out" else "";
      lines = lib.filter (x: x != "") [
        inLine
        outLine
      ];
    in
    lines;

  mkAddressFamily =
    af:
    let
      afName = af.family;
      maximumPaths = af.maximumPaths or null;
      redistribute = af.redistribute or [ ];
      neighbors = af.neighbors or [ ];
      maxPathsLines =
        if maximumPaths != null then [ "  maximum-paths ${toString maximumPaths}" ] else [ ];
      redistLines = lib.map (rd: "  redistribute ${rd.protocol} route-map ${rd.routeMap}") redistribute;
      nbRouteMapLines = lib.concatMap mkAddressFamilyNeighbor neighbors;
      indentedNbLines = lib.map (line: "  ${line}") nbRouteMapLines;
    in
    [ " address-family ${afName}" ] ++ maxPathsLines ++ redistLines ++ indentedNbLines ++ [ " exit-address-family" ];
in
{
  options.et42.router.frr = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable FRR routing with static route, prefix-list, route-map, and BGP abstractions.";
    };

    includeRfc1918Defaults = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Include RFC1918 blackhole routes, prefix lists, and route maps.";
    };

    rfc1918RouteMap = lib.mkOption {
      type = lib.types.str;
      default = "RM-RFC1918_V4";
      readOnly = true;
      description = "Name of the RFC1918 route map for host configs to reference.";
    };

    staticRoutes = lib.mkOption {
      type = lib.types.listOf lib.types.attrs;
      default = [ ];
      description = "List of static route definitions: { network, iface?, gateway?, distance?, blackhole? }.";
    };

    prefixLists = lib.mkOption {
      type = lib.types.listOf lib.types.attrs;
      default = [ ];
      description = "List of prefix-list entries: { name, seq, action, prefix, ge?, le? }.";
    };

    routeMaps = lib.mkOption {
      type = lib.types.listOf lib.types.attrs;
      default = [ ];
      description = "List of route-map entries: { name, seq, action, match?: list, set?: list }.";
    };

    bgpConfig = lib.mkOption {
      type = lib.types.submodule {
        options = {
          asn = lib.mkOption {
            type = lib.types.int;
            description = "Local BGP autonomous system number.";
          };

          routerId = lib.mkOption {
            type = lib.types.str;
            description = "BGP router-id (e.g. IP of loopback).";
          };

          neighbors = lib.mkOption {
            type = lib.types.listOf lib.types.attrs;
            default = [ ];
            description = "List of neighbors: { ip, remoteAs, routeMapIn?, routeMapOut?, softReconfigInbound? (default: true) }.";
          };

          extraConfig = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [ ];
            description = "Extra lines to add to the router bgp block (e.g. 'bgp bestpath as-path multipath-relax').";
          };

          addressFamilies = lib.mkOption {
            type = lib.types.listOf lib.types.attrs;
            default = [ ];
            description = "List of address-family blocks: { family, maximumPaths?, redistribute?: list of { protocol, routeMap }, neighbors?: list }.";
          };
        };
      };
      default = {
        asn = 0;
        routerId = null;
        neighbors = [ ];
        addressFamilies = [ ];
      };
      description = "BGP configuration parameters.";
    };
  };

  config = lib.mkIf config.et42.router.frr.enable {
    services.frr = {
      bfdd.enable = true;
      bgpd.enable = true;
      config =
        let
          header = [
            "hostname ${config.networking.hostName}"
            "domainname ${globals.zone}"
            "log syslog"
            "service password-encryption"
            "service integrated-vtysh-config"
          ];

          cfg = config.et42.router.frr;
          prefixLists = lib.map mkPrefixList (
            (if cfg.includeRfc1918Defaults then rfc1918PrefixListEntries else []) ++ cfg.prefixLists
          );
          staticRoutes = lib.map mkRoute (
            (if cfg.includeRfc1918Defaults then rfc1918BlackholeRoutes else []) ++ cfg.staticRoutes
          );
          routeMaps = lib.map mkRouteMap (
            (if cfg.includeRfc1918Defaults then rfc1918RouteMapEntries else []) ++ cfg.routeMaps
          );

          bgpConfig =
            if cfg.bgpConfig.asn != 0 then
              let
                bgp = cfg.bgpConfig;
                bgpHeader = [
                  "router bgp ${toString bgp.asn}"
                  " bgp router-id ${bgp.routerId}"
                ];

                bgpExtra = lib.map (line: " ${line}") bgp.extraConfig;
                bgpNeighbors = lib.concatMap mkNeighbor bgp.neighbors;
                bgpAddressFamilies = lib.concatMap (af: mkAddressFamily af) bgp.addressFamilies;
                bgpFooter = [ "exit" ];
              in
              bgpHeader ++ bgpExtra ++ bgpNeighbors ++ bgpAddressFamilies ++ bgpFooter
            else
              [ ];

          allConfig = header ++ prefixLists ++ staticRoutes ++ routeMaps ++ bgpConfig;
        in
        lib.concatStringsSep "\n" allConfig;
    };

    systemd.services.frr = {
      after = [
        "systemd-networkd.service"
        "network-online.target"
      ];
      wants = [ "network-online.target" ];
    };
  };
}
