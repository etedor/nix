{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.et42.router.miniupnpd;

  # helper function to format permission rules
  formatPermissionRule =
    rule:
    let
      action = rule.action or "deny";

      # use more secure default port ranges based on action
      defaultExtPorts = if action == "allow" then "1024-65535" else "0-65535";
      defaultIntPorts = if action == "allow" then "1024-65535" else "0-65535";

      extPorts =
        if rule ? extPort then
          "${toString rule.extPort}"
        else if rule ? extPortRange then
          "${toString rule.extPortRange.min}-${toString rule.extPortRange.max}"
        else
          defaultExtPorts;

      prefix = rule.prefix or "0.0.0.0/0";

      intPorts =
        if rule ? intPort then
          "${toString rule.intPort}"
        else if rule ? intPortRange then
          "${toString rule.intPortRange.min}-${toString rule.intPortRange.max}"
        else
          defaultIntPorts;

      description = optionalString (rule ? description) " \"${rule.description}\"";
    in
    "${action} ${extPorts} ${prefix} ${intPorts}${description}";

  # generate permission rules with automatic default deny
  permissionRules =
    let
      userRules = map formatPermissionRule cfg.permissionRules;
      # add default deny rule if not already present
      hasDefaultDeny = any (
        rule:
        (rule.action or "deny") == "deny"
        && (rule.prefix or "0.0.0.0/0") == "0.0.0.0/0"
        && !(rule ? extPort)
        && !(rule ? extPortRange)
        && !(rule ? intPort)
        && !(rule ? intPortRange)
      ) cfg.permissionRules;

      finalRules =
        if hasDefaultDeny || cfg.permissionRules == [ ] then
          userRules
        else
          userRules ++ [ "deny 0-65535 0.0.0.0/0 0-65535" ];
    in
    concatStringsSep "\n" finalRules;

  configFile = pkgs.writeText "miniupnpd.conf" (
    concatStringsSep "\n" (
      filter (line: line != "") [
        "ext_ifname=${cfg.externalInterface}"
        (optionalString (cfg.externalInterface6 != null) "ext_ifname6=${cfg.externalInterface6}")
        (optionalString (cfg.externalIP != null) "ext_ip=${cfg.externalIP}")
        (optionalString cfg.performStun "ext_perform_stun=${
          if cfg.allowFilteredStun then "allow-filtered" else "yes"
        }")
        (optionalString (cfg.stunHost != null && cfg.performStun) "ext_stun_host=${cfg.stunHost}")
        (optionalString (cfg.stunPort != 3478 && cfg.performStun) "ext_stun_port=${toString cfg.stunPort}")
        (concatMapStrings (range: "listening_ip=${range}\n") cfg.internalIPs)
        "http_port=${toString cfg.httpPort}"
        (optionalString (cfg.httpsPort != 0) "https_port=${toString cfg.httpsPort}")
        (optionalString (cfg.minissdpdSocket != null) "minissdpdsocket=${cfg.minissdpdSocket}")
        (optionalString cfg.disableIPv6 "ipv6_disable=yes")
        "enable_natpmp=${if cfg.natpmp then "yes" else "no"}"
        "enable_upnp=${if cfg.upnp then "yes" else "no"}"
        "min_lifetime=${toString cfg.minLifetime}"
        "max_lifetime=${toString cfg.maxLifetime}"
        (optionalString cfg.pcpAllowThirdParty "pcp_allow_thirdparty=yes")
        "upnp_table_name=${cfg.tableName}"
        "upnp_nat_table_name=${cfg.tableName}"
        "upnp_forward_chain=${cfg.chainName}"
        "upnp_nat_chain=${cfg.preroutingChainName}"
        "upnp_nat_postrouting_chain=${cfg.postroutingChainName}"
        (optionalString cfg.nftablesFamilySplit "upnp_nftables_family_split=yes")
        (optionalString (cfg.leaseFile != null) "lease_file=${cfg.leaseFile}")
        (optionalString (cfg.friendlyName != null) "friendly_name=${cfg.friendlyName}")
        (optionalString (cfg.manufacturerName != null) "manufacturer_name=${cfg.manufacturerName}")
        (optionalString (cfg.manufacturerUrl != null) "manufacturer_url=${cfg.manufacturerUrl}")
        (optionalString (cfg.modelName != null) "model_name=${cfg.modelName}")
        (optionalString (cfg.modelDescription != null) "model_description=${cfg.modelDescription}")
        (optionalString (cfg.modelUrl != null) "model_url=${cfg.modelUrl}")
        (optionalString (cfg.bitrateUp != null) "bitrate_up=${toString cfg.bitrateUp}")
        (optionalString (cfg.bitrateDown != null) "bitrate_down=${toString cfg.bitrateDown}")
        (optionalString (cfg.presentationUrl != null) "presentation_url=${cfg.presentationUrl}")
        "system_uptime=${if cfg.systemUptime then "yes" else "no"}"
        "notify_interval=${toString cfg.notifyInterval}"
        "uuid=${cfg.uuid}"
        (optionalString (cfg.serial != null) "serial=${cfg.serial}")
        (optionalString (cfg.modelNumber != null) "model_number=${cfg.modelNumber}")
        permissionRules
        cfg.appendConfig
      ]
    )
  );

  # use miniupnpd 2.3.9 with the filter rule deletion fix
  miniupnpd =
    let
      miniupnpd_2_3_9 = pkgs.miniupnpd.overrideAttrs (oldAttrs: {
        version = "2.3.9";
        src = pkgs.fetchurl {
          url = "https://miniupnp.tuxfamily.org/files/miniupnpd-2.3.9.tar.gz";
          sha256 = "0yxg08r2mpwgi6aypny2swla6svd2ql8di6kc4xbpcksd4ykrjv6";
        };
      });
    in
    miniupnpd_2_3_9.override { firewall = "nftables"; };
in
{
  options.et42.router.miniupnpd = {
    enable = mkEnableOption "MiniUPnP daemon";

    externalInterface = mkOption {
      type = types.str;
      description = "Name of the external interface.";
    };

    externalInterface6 = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Name of the external interface for IPv6 if different from IPv4.";
    };

    externalIP = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "External IP address to use (useful in double NAT setup).";
    };

    performStun = mkOption {
      type = types.bool;
      default = false;
      description = "Enable retrieving external public IP address from STUN server.";
    };

    allowFilteredStun = mkOption {
      type = types.bool;
      default = false;
      description = "Allow filtered STUN results when deciding whether to disable port forwarding.";
    };

    stunHost = mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "stunserver.stunprotocol.org";
      description = "STUN server hostname or IP address.";
    };

    stunPort = mkOption {
      type = types.int;
      default = 3478;
      description = "STUN server UDP port.";
    };

    internalIPs = mkOption {
      type = types.listOf types.str;
      example = [
        "192.168.1.1/24"
        "enp1s0"
      ];
      description = "The IP address ranges to listen on.";
    };

    httpPort = mkOption {
      type = types.int;
      default = 2869;
      description = "Port for HTTP (descriptions and SOAP) traffic. Set to 0 for autoselect.";
    };

    httpsPort = mkOption {
      type = types.int;
      default = 0;
      description = "Port for HTTPS. Set to 0 for autoselect.";
    };

    minissdpdSocket = mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "/var/run/minissdpd.sock";
      description = "Path to the UNIX socket used to communicate with MiniSSDPd.";
    };

    disableIPv6 = mkOption {
      type = types.bool;
      default = false;
      description = "Disable IPv6 support.";
    };

    natpmp = mkOption {
      type = types.bool;
      default = false;
      description = "Enable NAT-PMP support.";
    };

    upnp = mkOption {
      type = types.bool;
      default = false;
      description = "Enable UPnP support.";
    };

    minLifetime = mkOption {
      type = types.int;
      default = 120;
      description = "Minimum lifetime of a port mapping in seconds.";
    };

    maxLifetime = mkOption {
      type = types.int;
      default = 86400;
      description = "Maximum lifetime of a port mapping in seconds.";
    };

    pcpAllowThirdParty = mkOption {
      type = types.bool;
      default = false;
      description = "Allow THIRD_PARTY Option for MAP and PEER Opcodes.";
    };

    tableName = mkOption {
      type = types.str;
      default = "miniupnpd";
      description = "Name of the nftables table to use.";
    };

    chainName = mkOption {
      type = types.str;
      default = "miniupnpd";
      description = "Name of the nftables forward chain to use.";
    };

    preroutingChainName = mkOption {
      type = types.str;
      default = "prerouting_miniupnpd";
      description = "Name of the nftables prerouting chain to use.";
    };

    postroutingChainName = mkOption {
      type = types.str;
      default = "postrouting_miniupnpd";
      description = "Name of the nftables postrouting chain to use.";
    };

    preroutingPriority = mkOption {
      type = types.int;
      default = -90; # dstnat + 10
      description = "Priority for the prerouting chain.";
    };

    postroutingPriority = mkOption {
      type = types.int;
      default = 110; # srcnat + 10
      description = "Priority for the postrouting chain.";
    };

    nftablesFamilySplit = mkOption {
      type = types.bool;
      default = false;
      description = "Split nftables rules by family (IPv4/IPv6).";
    };

    leaseFile = mkOption {
      type = types.nullOr types.str;
      default = "/var/lib/miniupnpd/upnp.leases";
      description = "Lease file location.";
    };

    friendlyName = mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "MiniUPnPd router";
      description = "Name of this service.";
    };

    manufacturerName = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Manufacturer name.";
    };

    manufacturerUrl = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Manufacturer URL.";
    };

    modelName = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Model name.";
    };

    modelDescription = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Model description.";
    };

    modelUrl = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Model URL.";
    };

    bitrateUp = mkOption {
      type = types.nullOr types.int;
      default = null;
      example = 1000000;
      description = "Upstream bitrate in bits per second.";
    };

    bitrateDown = mkOption {
      type = types.nullOr types.int;
      default = null;
      example = 10000000;
      description = "Downstream bitrate in bits per second.";
    };

    presentationUrl = mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "http://192.168.1.1/";
      description = "Presentation URL for the UPnP device.";
    };

    systemUptime = mkOption {
      type = types.bool;
      default = true;
      description = "Report system uptime instead of daemon uptime.";
    };

    notifyInterval = mkOption {
      type = types.int;
      default = 900;
      description = "SSDP notify interval in seconds.";
    };

    uuid = mkOption {
      type = types.str;
      default = "00000000-0000-0000-0000-000000000000";
      description = "UUID for the UPnP device.";
    };

    serial = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Serial number for the UPnP device.";
    };

    modelNumber = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Model number for the UPnP device.";
    };

    permissionRules = mkOption {
      type = types.listOf types.attrs;
      default = [
        {
          action = "deny";
          prefix = "0.0.0.0/0";
        }
      ];
      example = [
        {
          action = "allow";
          extPortRange = {
            min = 1024;
            max = 65535;
          };
          prefix = "192.168.1.0/24";
          intPortRange = {
            min = 1024;
            max = 65535;
          };
        }
        {
          action = "deny";
          prefix = "0.0.0.0/0";
        }
      ];
      description = ''
        UPnP permission rules. Each rule is an attribute set with:
        - action: "allow" or "deny"
        - extPort or extPortRange: external port(s) to match
        - prefix: IP prefix to match
        - intPort or intPortRange: internal port(s) to match
        - description: match requests whose description matches the given regex
      '';
    };

    appendConfig = mkOption {
      type = types.lines;
      default = "";
      description = "Additional configuration lines appended to the MiniUPnP config.";
    };
  };

  config = mkIf cfg.enable {
    services.miniupnpd.enable = false;

    networking.nftables = {
      enable = true;
      ruleset = ''
        # custom miniupnpd table
        table inet ${cfg.tableName} {
          chain ${cfg.chainName} {
          }

          chain ${cfg.preroutingChainName} {
            type nat hook prerouting priority ${toString cfg.preroutingPriority}; policy accept;
          }

          chain ${cfg.postroutingChainName} {
            type nat hook postrouting priority ${toString cfg.postroutingPriority}; policy accept;
          }
        }
      '';
    };

    systemd.services.miniupnpd-et42 =
      let
        pidFile = "/run/miniupnpd.pid";
      in
      {
        description = "MiniUPnP daemon";
        conflicts = [ "miniupnpd.service" ];
        after = [ "network.target" ];
        wantedBy = [ "multi-user.target" ];

        preStart = ''
          mkdir -p "$(dirname "${cfg.leaseFile}")"
          touch "${cfg.leaseFile}"
          chmod 644 "${cfg.leaseFile}"
        '';

        serviceConfig = {
          Type = "simple";
          PIDFile = pidFile;
          ExecStart = "${miniupnpd}/bin/miniupnpd -d -f ${configFile}";
          ExecStopPost = "${pkgs.coreutils}/bin/rm -f ${pidFile}";
          Restart = "on-failure";
          RestartSec = "5s";
        };
      };
  };
}
