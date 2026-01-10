{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.et42.router.cake;

  # link type presets for overhead and compensation
  linkTypes = {
    docsis = {
      OverheadBytes = 18;
      CompensationMode = "none";
    };
    "5g" = {
      OverheadBytes = 44;
      CompensationMode = "none";
    };
    lte = {
      OverheadBytes = 44;
      CompensationMode = "none";
    };
    vdsl = {
      OverheadBytes = 30;
      CompensationMode = "ptm";
    };
    adsl = {
      OverheadBytes = 32;
      CompensationMode = "ptm";
    };
    pppoe = {
      OverheadBytes = 8;
      CompensationMode = "none";
    };
    ethernet = {
      OverheadBytes = 38;
      CompensationMode = "none";
    };
  };

  # default CAKE settings
  defaultSettings = {
    MPUBytes = 64;
    PriorityQueueingPreset = "diffserv4";
    NAT = true;
    Wash = false;
    SplitGSO = true;
    FlowIsolationMode = "triple";
    RTT = "100ms";
  };

  # merge profile with defaults and link type
  mkProfile =
    interface: direction:
    let
      profile = interface.${direction};
      linkPreset = if interface.linkType != null then linkTypes.${interface.linkType} else { };
    in
    defaultSettings // linkPreset // profile;

  # generate CAKE tc options from a profile attrset
  mkCAKEOpts =
    profile:
    let
      formatBandwidth = bw: if builtins.match ".*bit$" bw != null then bw else "${bw}bit";

      bandwidthStr =
        if profile ? Bandwidth then
          let
            bwValue = formatBandwidth profile.Bandwidth;
            autorateStr =
              if (profile ? AutoRateIngress && profile.AutoRateIngress) then " autorate-ingress" else "";
          in
          "bandwidth ${bwValue}${autorateStr}"
        else
          null;

      optionFormatters = {
        RTT = v: "rtt ${v}";
        MPUBytes = v: "mpu ${toString v}";
        OverheadBytes = v: "overhead ${toString v}";
        CompensationMode =
          v:
          {
            ptm = "ptm";
            none = "noatm";
            raw = "raw";
          }
          .${v} or "raw";
        FlowIsolationMode =
          v:
          {
            triple = "triple-isolate";
            dual = "dual-srchost";
            hosts = "srchost";
            flows = "flows";
          }
          .${v} or "flows";
        NAT = v: if v then "nat" else "nonat";
        Wash = v: if v then "wash" else "nowash";
        AckFilter = v: if v then "ack-filter" else "no-ack-filter";
        SplitGSO = v: if v then "split-gso" else "no-split-gso";
        PriorityQueueingPreset = v: v;
      };

      processedOptions = builtins.concatLists (
        builtins.map
          (
            name:
            let
              formatter = optionFormatters.${name} or (_: "");
              formatted = formatter profile.${name};
            in
            if formatted != "" then [ formatted ] else [ ]
          )
          (
            builtins.filter (
              name: name != "Bandwidth" && name != "AutoRateIngress" && optionFormatters ? ${name}
            ) (builtins.attrNames profile)
          )
      );
    in
    builtins.concatStringsSep " " (
      (if bandwidthStr != null then [ bandwidthStr ] else [ ]) ++ processedOptions
    );

  # interface submodule
  interfaceModule = types.submodule {
    options = {
      device = mkOption {
        type = types.str;
        description = "network interface name (e.g., wan0)";
      };

      linkType = mkOption {
        type = types.nullOr (
          types.enum [
            "docsis"
            "5g"
            "lte"
            "vdsl"
            "adsl"
            "pppoe"
            "ethernet"
          ]
        );
        default = null;
        description = "link type preset for overhead/compensation (overridable)";
      };

      egress = mkOption {
        type = types.attrs;
        description = "CAKE profile for egress (upload) traffic - Bandwidth required";
        example = {
          Bandwidth = "250Mbit";
          RTT = "100ms";
        };
      };

      ingress = mkOption {
        type = types.attrs;
        description = "CAKE profile for ingress (download) traffic - Bandwidth required";
        example = {
          Bandwidth = "2000Mbit";
          AutoRateIngress = true;
        };
      };
    };
  };

  interfaceNames = attrNames cfg.interfaces;
  interfaceCount = length interfaceNames;
in
{
  options.et42.router.cake = {
    enable = mkEnableOption "CAKE QoS traffic shaping";

    interfaces = mkOption {
      type = types.attrsOf interfaceModule;
      default = { };
      description = "network interfaces to configure with CAKE";
      example = {
        wan0 = {
          device = "wan0";
          linkType = "docsis";
          egress = {
            Bandwidth = "250Mbit";
          };
          ingress = {
            Bandwidth = "2000Mbit";
          };
        };
      };
    };

    # expose mkCAKEOpts for external use (e.g., cake-governor)
    _mkCAKEOpts = mkOption {
      type = types.unspecified;
      default = mkCAKEOpts;
      internal = true;
      description = "internal: CAKE options generator function";
    };

    # expose merged profiles for external use
    _profiles = mkOption {
      type = types.unspecified;
      default = mapAttrs (name: iface: {
        egress = mkProfile iface "egress";
        ingress = mkProfile iface "ingress";
      }) cfg.interfaces;
      internal = true;
      description = "internal: merged CAKE profiles";
    };
  };

  config = mkIf cfg.enable {
    assertions = flatten (
      mapAttrsToList (name: iface: [
        {
          assertion = iface.egress ? Bandwidth;
          message = "et42.router.cake.interfaces.${name}.egress.Bandwidth is required";
        }
        {
          assertion = iface.ingress ? Bandwidth;
          message = "et42.router.cake.interfaces.${name}.ingress.Bandwidth is required";
        }
      ]) cfg.interfaces
    );

    boot.kernelModules = [ "ifb" ];

    systemd.services.ifb-init = {
      description = "create IFB interfaces for CAKE ingress shaping";
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];
      path = [
        pkgs.iproute2
        pkgs.kmod
      ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = pkgs.writeShellScript "ifb-init" ''
          set -eux
          modprobe ifb numifbs=${toString interfaceCount}

          ${concatStringsSep "\n" (
            mapAttrsToList (name: iface: ''
              iface="${iface.device}"
              IFB="ifb4$iface"

              if ! ip link show "$IFB" &>/dev/null; then
                ip link add name "$IFB" type ifb
              fi
              ip link set "$IFB" up

              tc qdisc del dev "$iface" ingress 2>/dev/null || true
              tc qdisc add dev "$iface" handle ffff: ingress

              # restore DSCP from conntrack, redirect to IFB
              tc filter add dev "$iface" parent ffff: protocol all prio 10 u32 \
                match u32 0 0 flowid 1:1 \
                action ctinfo dscp 0xfc000000 0x01000000 pipe \
                action mirred egress redirect dev "$IFB"
            '') cfg.interfaces
          )}
        '';
      };
    };

    systemd.services.qos-init = {
      description = "configure CAKE QoS on WAN interfaces";
      after = [
        "network.target"
        "systemd-networkd.service"
        "ifb-init.service"
      ];
      wants = [
        "network.target"
        "systemd-networkd.service"
      ];
      requires = [ "ifb-init.service" ];
      wantedBy = [ "multi-user.target" ];
      path = [ pkgs.iproute2 ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = pkgs.writeShellScript "qos-init" ''
          set -ex

          ${concatStringsSep "\n" (
            mapAttrsToList (
              name: iface:
              let
                egressProfile = mkProfile iface "egress";
                ingressProfile = mkProfile iface "ingress";
              in
              ''
                # ${name}: egress shaping on ${iface.device}
                tc qdisc del dev ${iface.device} root 2>/dev/null || true
                tc qdisc add dev ${iface.device} root cake ${mkCAKEOpts egressProfile}

                # ${name}: ingress shaping on ifb4${iface.device}
                tc qdisc del dev ifb4${iface.device} root 2>/dev/null || true
                tc qdisc add dev ifb4${iface.device} root cake ${mkCAKEOpts ingressProfile}
              ''
            ) cfg.interfaces
          )}
        '';
      };
    };
  };
}
