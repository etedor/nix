{
  config,
  lib,
  pkgs-unstable,
  ...
}:

let
  cfg = config.et42.router.dhcp;

  # helper functions for test expressions
  # convert MAC to hex string without colons
  macToHex = mac: "0x${builtins.replaceStrings [ ":" ] [ "" ] mac}";

  # create a test for exact MAC address match
  macTest = mac: "pkt4.mac == ${macToHex mac}";

  # create a test for OUI match (first 3 bytes of MAC)
  ouiTest =
    oui:
    let
      # handle both formats: "00:11:22" and "001122"
      normalizedOui =
        if builtins.match "^[0-9a-fA-F:]+$" oui != null then
          builtins.replaceStrings [ ":" ] [ "" ] oui
        else
          oui;
    in
    "substring(pkt4.mac, 0, 3) == 0x${normalizedOui}";

  # create a test for vendor class identifier
  vendorTest = vendor: "option[60].text == '${vendor}'";

  # create a test for vendor class identifier prefix
  vendorPrefixTest =
    prefix: "substring(option[60].text, 0, ${toString (builtins.stringLength prefix)}) == '${prefix}'";

  # create a test for DHCP relay agent information
  relayTest =
    value:
    "substring(option[82].option[1].hex, -${toString (builtins.stringLength value)}, all) == '${value}'";

  # create a test for interface
  interfaceTest = vlan: "pkt.iface == '${vlan}'";

  # join multiple tests with OR, adding parentheses for complex expressions
  joinOr =
    tests:
    let
      filteredTests = builtins.filter (t: t != "") tests;
    in
    if builtins.length filteredTests == 0 then
      ""
    else if builtins.length filteredTests == 1 then
      builtins.elemAt filteredTests 0
    else
      lib.concatStringsSep " or " (
        map (
          t:
          if builtins.match ".* (and|or) .*" t != null then
            "(${t})" # add parentheses if the test contains and/or
          else
            t
        ) filteredTests
      );

  # join multiple tests with AND, adding parentheses for complex expressions
  joinAnd =
    tests:
    let
      filteredTests = builtins.filter (t: t != "") tests;
    in
    if builtins.length filteredTests == 0 then
      ""
    else if builtins.length filteredTests == 1 then
      builtins.elemAt filteredTests 0
    else
      lib.concatStringsSep " and " (
        map (
          t:
          if builtins.match ".* (and|or) .*" t != null then
            "(${t})" # add parentheses if the test contains and/or
          else
            t
        ) filteredTests
      );

  # create a test for a list of MAC addresses
  macListTest = macs: joinOr (map macTest macs);

  # create a test for a list of OUIs
  ouiListTest = ouis: joinOr (map ouiTest ouis);

  # create a test for SSID in DHCP relay agent information (option 82)
  # checks if the SSID in option 82 ends with the provided string
  ssidEndsWith =
    suffix:
    let
      suffixLength = builtins.stringLength suffix;

    in
    "substring(option[82].option[1].hex, -${toString suffixLength}, all) == '${suffix}'";

  # build a device class test expression from device definition
  buildDeviceTest =
    devices:
    let
      # build individual test components
      macTests =
        if devices ? macs && builtins.length devices.macs > 0 then
          [
            (macListTest devices.macs)
          ]
        else
          [ ];

      ouiTests =
        if devices ? ouis && builtins.length devices.ouis > 0 then
          [
            (ouiListTest devices.ouis)
          ]
        else
          [ ];

      ssidTests =
        if devices ? ssidSuffixes && builtins.length devices.ssidSuffixes > 0 then
          map ssidEndsWith devices.ssidSuffixes
        else
          [ ];

      memberTests =
        if devices ? memberOf && builtins.length devices.memberOf > 0 then
          let
            memberList = joinOr (map (cls: "member('${cls}')") devices.memberOf);
          in
          if memberList != "" then [ memberList ] else [ ]
        else
          [ ];

      interfaceTests = if devices ? interface then [ (interfaceTest devices.interface) ] else [ ];

      relayTests =
        if devices ? relay && builtins.length devices.relay > 0 then map relayTest devices.relay else [ ];

      vendorTests =
        if devices ? vendors && builtins.length devices.vendors > 0 then
          map vendorTest devices.vendors
        else
          [ ];

      vendorPrefixTests =
        if devices ? vendorPrefixes && builtins.length devices.vendorPrefixes > 0 then
          map vendorPrefixTest devices.vendorPrefixes
        else
          [ ];

      rawTests = devices.raw or [ ];

      # combine all tests
      allTests =
        macTests
        ++ ouiTests
        ++ ssidTests
        ++ memberTests
        ++ interfaceTests
        ++ relayTests
        ++ vendorTests
        ++ vendorPrefixTests
        ++ rawTests;
    in
    joinOr allTests;

  # process classes with exclusivity
  processClassesWithExclusivity =
    classes:
    let

      # process classes one by one, maintaining a list of classes by exclusion group
      processWithExclusivity =
        remainingClasses: processedClasses: classesByGroup:
        if builtins.length remainingClasses == 0 then
          processedClasses
        else

          let
            currentClass = builtins.head remainingClasses;
            restClasses = builtins.tail remainingClasses;

            # build the base test expression
            baseTest = currentClass.test or (buildDeviceTest currentClass);

            group = currentClass.exclusionGroup or null;
            isExclusive = currentClass.exclusive or false;

            # add exclusion tests for previously defined classes in the same group
            # but only if this class is exclusive
            testWithExclusions =
              if group != null && isExclusive && classesByGroup ? ${group} then
                let
                  previousClassesInGroup = classesByGroup.${group};
                  exclusionTests = map (name: "not member('${name}')") previousClassesInGroup;
                  combinedTest =
                    if baseTest != "" && builtins.length exclusionTests > 0 then
                      "(${baseTest}) and ${joinAnd exclusionTests}"
                    else if builtins.length exclusionTests > 0 then
                      joinAnd exclusionTests
                    else
                      baseTest;
                in
                combinedTest
              else
                baseTest;

            processedClass = {
              name = currentClass.name;
              test = testWithExclusions;

            }
            // (
              if currentClass ? options && builtins.length currentClass.options > 0 then
                { "option-data" = currentClass.options; }
              else
                { }
            )
            // (
              if currentClass ? routes && builtins.length currentClass.routes > 0 then
                {
                  "option-data" = (currentClass.options or [ ]) ++ [
                    {
                      name = "classless-static-route";
                      code = 121;
                      data = lib.concatMapStringsSep ", " (
                        route: "${route.prefix} - ${route.gateway}"
                      ) currentClass.routes;
                    }
                    {
                      name = "routers";
                      code = 3;
                      data = "";
                    }
                  ];
                }
              else
                { }
            )
            // (
              if currentClass ? comment && currentClass.comment != "" then
                { comment = currentClass.comment; }
              else
                { }
            );

            newClassesByGroup =
              if group != null then
                classesByGroup
                // {
                  ${group} = (classesByGroup.${group} or [ ]) ++ [ currentClass.name ];
                }
              else
                classesByGroup;
          in
          processWithExclusivity restClasses (processedClasses ++ [ processedClass ]) newClassesByGroup;
    in
    processWithExclusivity classes [ ] { };

  # process a reservation - include only fields that are defined
  processReservation =
    res:
    let
      # convert MAC/IP to hw-address/ip-address
      base = {
        hw-address = res.mac or res.hw-address; # accept either MAC or hw-address
        ip-address = res.ip or res.ip-address; # accept either IP or ip-address
        hostname = res.hostname;
      };

      withClasses =
        if res ? client-classes && builtins.length res.client-classes > 0 then
          base // { client-classes = res.client-classes; }
        else
          base;

      withOptions =
        if res ? option-data && builtins.length res.option-data > 0 then
          withClasses // { option-data = res.option-data; }
        else
          withClasses;

      final = lib.foldl (
        acc: key:
        if
          res ? ${key}
          && !(builtins.elem key [
            "mac"
            "hw-address"
            "ip"
            "ip-address"
            "hostname"
            "client-classes"
            "option-data"
          ])
        then
          acc // { ${key} = res.${key}; }
        else
          acc
      ) withOptions (builtins.attrNames res);
    in
    final;

  # generate shared network configuration from VLAN definitions
  generateSharedNetwork =
    {
      network,
      reservations,
      mkOptions,
      sharedNetworkName,
      authorizedRelayAgents,
    }:
    let
      # generate individual subnets
      subnets = lib.mapAttrsToList (
        vlanName: vlanConfig:
        let
          pools = vlanConfig.pools or [ ];
          # process reservations for this subnet
          subnetReservations = map processReservation (reservations.${vlanConfig.subnet} or [ ]);
        in
        {
          subnet = vlanConfig.subnet;
          pools = pools;
          option-data = mkOptions vlanName vlanConfig;
          reservations = subnetReservations;
        }
      ) network.vlans;

      # create the shared network structure
      sharedNetwork = {
        name = sharedNetworkName;
        subnet4 = lib.imap0 (i: s: s // { id = i + 1; }) subnets;
      }
      // (lib.optionalAttrs (builtins.length authorizedRelayAgents > 0) {
        relay = {
          ip-addresses = authorizedRelayAgents;
        };
      });
    in
    [ sharedNetwork ];

  # create DHCP option data for a VLAN
  mkVlanOptions = routerIp: domainName: dnsServers: ntpServer: [
    {
      name = "routers";
      data = routerIp;
    }
    {
      name = "domain-name";
      data = domainName;
    }
    {
      name = "domain-name-servers";
      data = if builtins.isList dnsServers then lib.concatStringsSep "," dnsServers else dnsServers;
    }
    {
      name = "ntp-servers";
      data = ntpServer;
    }
  ];
in
{
  options.et42.router.dhcp = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "enable DHCP server with class-based configuration.";
    };

    network = lib.mkOption {
      type = lib.types.attrs;
      default = { };
      description = "network structure with VLAN to subnet mapping.";
    };

    sharedNetworkName = lib.mkOption {
      type = lib.types.str;
      default = "enterprise-network";
      description = "name of the shared network containing all subnets.";
    };

    authorizedRelayAgents = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "list of IP addresses authorized to relay DHCP requests to this shared network.";
    };

    classes = lib.mkOption {
      type = lib.types.listOf lib.types.attrs;
      default = [ ];
      description = "client class definitions for device classification.";
    };

    reservations = lib.mkOption {
      type = lib.types.attrs;
      default = { };
      description = "fixed IP reservations by subnet.";
    };

    optionDefs = lib.mkOption {
      type = lib.types.listOf lib.types.attrs;
      default = [
        {
          name = "1APC";
          code = 43;
          space = "dhcp4";
          type = "string";
        }
      ];
      description = "custom DHCP option definitions.";
    };

    validLifetime = lib.mkOption {
      type = lib.types.int;
      default = 1800;
      description = "DHCP lease valid lifetime in seconds";
    };

    renewTimer = lib.mkOption {
      type = lib.types.int;
      default = 600;
      description = "DHCP lease renew timer in seconds";
    };

    rebindTimer = lib.mkOption {
      type = lib.types.int;
      default = 1200;
      description = "DHCP lease rebind timer in seconds";
    };

    earlyGlobalReservationsLookup = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "control global reservation lookup timing";
    };

    dnsServers = lib.mkOption {
      type = lib.types.either (lib.types.listOf lib.types.str) lib.types.str;
      description = "DNS server IP address(es) to provide to DHCP clients, can be a single IP or a list";
    };

    # maintain backward compatibility
    dnsServer = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "legacy option, use dnsServers instead";
    };

    domainName = lib.mkOption {
      type = lib.types.str;
      description = "domain name to provide to DHCP clients";
    };

    ntpServer = lib.mkOption {
      type = lib.types.str;
      default = "192.0.2.123";
      description = "NTP server IP address to provide to DHCP clients";
    };

    hooksLibraries = lib.mkOption {
      type = lib.types.listOf lib.types.attrs;
      default = [ ];
      description = "hooks libraries for Kea DHCP4 service";
    };

    ddns = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "enable Dynamic DNS updates from Kea to DNS server";
      };

      forwardZone = lib.mkOption {
        type = lib.types.str;
        default = "";
        description = "forward zone for DDNS updates";
      };

      reverseZones = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "reverse zones for DDNS updates";
      };

      keyName = lib.mkOption {
        type = lib.types.str;
        default = "kea-ddns";
        description = "name of the TSIG key for DDNS updates";
      };

      keyAlgorithm = lib.mkOption {
        type = lib.types.str;
        default = "hmac-sha256";
        description = "algorithm for the TSIG key";
      };

      keySecretFile = lib.mkOption {
        type = lib.types.nullOr lib.types.path;
        default = null;
        description = "path to a file containing just the base64-encoded TSIG key secret";
      };

      serverIp = lib.mkOption {
        type = lib.types.str;
        default = "127.0.0.1";
        description = "IP address of the DNS server for DDNS updates";
      };

      serverPort = lib.mkOption {
        type = lib.types.port;
        default = 53;
        description = "port of the DNS server for DDNS updates";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    # use kea from unstable (3.0.2) instead of stable (2.6.3)
    # required for client-classes support in pools
    nixpkgs.overlays = [
      (final: prev: {
        kea = pkgs-unstable.kea;
      })
    ];

    services.kea.dhcp-ddns = lib.mkIf cfg.ddns.enable {
      enable = true;

      settings = {
        ip-address = "127.0.0.1";
        port = 53001;
        control-socket = {
          socket-type = "unix";
          socket-name = "/run/kea/kea-ddns-ctrl-socket";
        };

        tsig-keys = lib.mkIf (cfg.ddns.keySecretFile != null) [
          {
            name = cfg.ddns.keyName;
            algorithm = cfg.ddns.keyAlgorithm;
            secret-file = cfg.ddns.keySecretFile;
          }
        ];

        forward-ddns = {
          ddns-domains = [
            {
              name = "${cfg.ddns.forwardZone}.";
              key-name = cfg.ddns.keyName;
              dns-servers = [
                {
                  ip-address = cfg.ddns.serverIp;
                  port = cfg.ddns.serverPort;
                }
              ];
            }
          ];
        };

        reverse-ddns = {
          ddns-domains = map (zone: {
            name = "${zone}.";
            key-name = cfg.ddns.keyName;

            dns-servers = [
              {
                ip-address = cfg.ddns.serverIp;
                port = cfg.ddns.serverPort;
              }
            ];
          }) cfg.ddns.reverseZones;
        };

        loggers = [
          {
            name = "kea-dhcp-ddns";
            output_options = [
              {
                output = "syslog";
                pattern = "%-5p %m\n";
              }
            ];
            severity = "INFO";
            debuglevel = 0;
          }
        ];
      };
    };
    services.kea.dhcp4 = {
      enable = true;
      settings =
        let
          # process device classes with exclusivity
          processedClasses = processClassesWithExclusivity cfg.classes;

          # get effective DNS servers (maintain backward compatibility)
          effectiveDnsServers =
            if cfg.dnsServer != "" then
              if builtins.isList cfg.dnsServers && builtins.length cfg.dnsServers > 0 then
                cfg.dnsServers
              else
                cfg.dnsServer
            else
              cfg.dnsServers;

          # create a function to generate VLAN options with the configured values
          mkOptions =
            vlanName: vlanConfig:
            let
              baseOptions = mkVlanOptions vlanConfig.router cfg.domainName effectiveDnsServers cfg.ntpServer;
            in
            baseOptions ++ (vlanConfig.options or [ ]);

          # generate shared network configuration
          sharedNetworkConfig = generateSharedNetwork {
            network = cfg.network;
            reservations = cfg.reservations;
            mkOptions = mkOptions;
            sharedNetworkName = cfg.sharedNetworkName;
            authorizedRelayAgents = cfg.authorizedRelayAgents;
          };

          # DDNS configuration for DHCP
          ddnsConfig = lib.optionalAttrs cfg.ddns.enable {
            "dhcp-ddns" = {
              "enable-updates" = true;
              "server-ip" = "127.0.0.1";
              "server-port" = 53001;
              "sender-ip" = "127.0.0.1";
              "sender-port" = 0;
              "max-queue-size" = 1024;
              "ncr-protocol" = "UDP";
              "ncr-format" = "JSON";
            };

            "ddns-conflict-resolution-mode" = "no-check-with-dhcid";
            "ddns-generated-prefix" = "dynamic";
            "ddns-override-client-update" = true;
            "ddns-override-no-update" = true;
            "ddns-qualifying-suffix" = cfg.domainName;
            "ddns-replace-client-name" = "when-not-present";
            "hostname-char-set" = "[^A-Za-z0-9.-]";
            "hostname-char-replacement" = "-";
          };
        in
        {
          "interfaces-config" = {
            interfaces = config.et42.router.vlan.names;
          };

          "lease-database" = {
            type = "memfile";
            persist = true;
            name = "/var/lib/kea/dhcp4.leases";
            # kea 3.0 is more strict about paths - ensure state directory exists
            lfc-interval = 3600;
          };

          "valid-lifetime" = cfg.validLifetime;
          "renew-timer" = cfg.renewTimer;
          "rebind-timer" = cfg.rebindTimer;

          # control global reservation lookup timing
          "early-global-reservations-lookup" = cfg.earlyGlobalReservationsLookup;

          hooks-libraries = cfg.hooksLibraries;

          option-def = cfg.optionDefs;
          client-classes = processedClasses;
          shared-networks = sharedNetworkConfig;
        }
        // ddnsConfig;
    };

    # set KEA_DHCP_DATA_DIR environment variable for kea 3.0 path validation
    # https://gitlab.isc.org/isc-projects/kea/-/issues/3831
    systemd.services.kea-dhcp4-server.environment = {
      KEA_DHCP_DATA_DIR = "/var/lib/kea";
    };
  };
}
