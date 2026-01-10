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

  mkNeighbor =
    nb:
    let
      ip = nb.ip;
      remoteAs = nb.remoteAs;
      softReconfig = nb.softReconfigInbound or true;
      softReconfigLine = if softReconfig then " neighbor ${ip} soft-reconfiguration inbound" else "";
    in

    [ " neighbor ${ip} remote-as ${toString remoteAs}" ]
    ++ (if softReconfig then [ softReconfigLine ] else [ ]);

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
      redistribute = af.redistribute or [ ];
      neighbors = af.neighbors or [ ];
      redistLines = lib.map (rd: "  redistribute ${rd.protocol} route-map ${rd.routeMap}") redistribute;
      nbRouteMapLines = lib.concatMap mkAddressFamilyNeighbor neighbors;
      indentedNbLines = lib.map (line: "  ${line}") nbRouteMapLines;
    in
    [ " address-family ${afName}" ] ++ redistLines ++ indentedNbLines ++ [ " exit-address-family" ];
in
{
  options.et42.router.frr = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable FRR routing with static route, prefix-list, route-map, and BGP abstractions.";
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

          addressFamilies = lib.mkOption {
            type = lib.types.listOf lib.types.attrs;
            default = [ ];
            description = "List of address-family blocks: { family, redistribute?: list of { protocol, routeMap }, neighbors?: list }.";
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

          prefixLists = lib.map mkPrefixList config.et42.router.frr.prefixLists;
          staticRoutes = lib.map mkRoute config.et42.router.frr.staticRoutes;
          routeMaps = lib.map mkRouteMap config.et42.router.frr.routeMaps;

          bgpConfig =
            if config.et42.router.frr.bgpConfig.asn != 0 then
              let
                bgp = config.et42.router.frr.bgpConfig;
                bgpHeader = [
                  "router bgp ${toString bgp.asn}"
                  " bgp router-id ${bgp.routerId}"
                ];

                bgpNeighbors = lib.concatMap mkNeighbor bgp.neighbors;
                bgpAddressFamilies = lib.concatMap (af: mkAddressFamily af) bgp.addressFamilies;
                bgpFooter = [ "exit" ];
              in
              bgpHeader ++ bgpNeighbors ++ bgpAddressFamilies ++ bgpFooter
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
