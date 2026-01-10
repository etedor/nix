{
  config,
  lib,
  pkgs,
  specialArgs,
  ...
}:

let
  w0IF = "wan0";
  w0Distance = 10;
  w0Mon1 = "75.75.75.75";
  w0Mon2 = "75.75.76.76";

  w1IF = "wan1";
  w1Gateway = "192.168.12.1";
  w1Distance = 15;
  w1Mon1 = "208.67.222.222";
  w1Mon2 = "208.67.220.220";

  useMonConf = {
    interface = w1IF;
    thresholds = [
      "25GB"
      "35GB"
      "45GB"
      "50GB"
    ];
    resetDay = 1;
  };

  mkMonitorRoutes =
    {
      iface ? null,
      gateway ? null,
      ips,
    }:
    lib.flatten (
      map (ip: [
        (
          if gateway != null then
            {
              network = "${ip}/32";
              gateway = gateway;
            }
          else
            {
              network = "${ip}/32";
              iface = iface;
            }
        )
        {
          network = "${ip}/32";
          blackhole = true;
        }
      ]) ips
    );

  failMon = pkgs.runCommand "failure-monitor" { } ''
    install -m755 ${
      pkgs.replaceVars ./failure-monitor.sh {
        conntrack = pkgs.conntrack-tools;
        curl = pkgs.curl;
        hostname = config.networking.hostName;
        frr = pkgs.frr;

        wan0 = w0IF;
        wan1 = w1IF;

        pushoverPath = config.age.secrets.pushover.path;
      }
    } $out
  '';

  useMon = pkgs.runCommand "usage-monitor" { } ''
    install -m755 ${
      pkgs.replaceVars ./usage-monitor.py {
        vnstat = pkgs.vnstat;

        interface = useMonConf.interface;
        thresholds = lib.concatStringsSep "," useMonConf.thresholds;
        resetDay = toString useMonConf.resetDay;

        pushoverPath = config.age.secrets.pushover.path;
      }
    } $out
  '';

  mkFailoverService =
    {
      iface,
      distance,
      mon1,
      mon2,
      gateway ? "",
    }:
    {
      description = "${iface} failover monitor";

      after = [
        "network-online.target"
        "frr.service"
      ];
      wants = [ "network-online.target" ];
      requires = [ "frr.service" ];
      wantedBy = [ "multi-user.target" ];

      path = with pkgs; [
        bash
        conntrack-tools
        curl
        frr
        iproute2
        iputils
      ];
      serviceConfig = {
        Type = "simple";
        User = "root";
        Group = "frrvty";
        ExecStart = "${failMon} ${iface} ${toString distance} ${mon1} ${mon2} \"${gateway}\"";
        Restart = "always";
        RestartSec = "5s";
        CapabilityBoundingSet = "CAP_NET_ADMIN CAP_NET_RAW";
        AmbientCapabilities = "CAP_NET_ADMIN CAP_NET_RAW";
      };
    };
in
{
  age.secrets = {
    pushover = {
      file = "${specialArgs.secretsCommon}/pushover.age";
      owner = "root";
      group = "root";
      mode = "400";
    };
  };

  systemd.services = {
    "failmon-${w0IF}" = mkFailoverService {
      iface = w0IF;
      distance = w0Distance;
      mon1 = w0Mon1;
      mon2 = w0Mon2;
    };
    "failmon-${w1IF}" = mkFailoverService {
      iface = w1IF;
      distance = w1Distance;
      mon1 = w1Mon1;
      mon2 = w1Mon2;
      gateway = w1Gateway;
    };

    "usemon-${w1IF}" = {
      description = "${w1IF} data usage monitor";

      after = [
        "network-online.target"
        "vnstat.service"
      ];
      wants = [ "network-online.target" ];
      requires = [ "vnstat.service" ];
      wantedBy = [ "multi-user.target" ];

      path = with pkgs; [
        (python311.withPackages (
          ps: with ps; [
            pushover-complete
          ]
        ))
        vnstat
      ];

      serviceConfig = {
        Type = "oneshot";
        User = "root";
        ExecStart = "${useMon}";
        TimeoutStartSec = "60s";
        TimeoutStopSec = "10s";
        StandardOutput = "journal";
        StandardError = "journal";
      };
    };
  };

  systemd.timers."usemon-${w1IF}" = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "5m";
      OnUnitActiveSec = "15m";
      Unit = "usemon-${w1IF}.service";
    };
  };

  services.vnstat = {
    enable = true;
  };

  systemd.network.networks = {
    "11-${w0IF}" = {
      matchConfig.Name = w0IF;
      dhcpV4Config = {
        UseDNS = false;
        UseRoutes = false;
      };
    };
    "13-${w1IF}" = {
      matchConfig.Name = w1IF;
      dhcpV4Config = {
        UseDNS = false;
        UseRoutes = false;
      };
    };
  };

  et42.router.frr.staticRoutes =
    mkMonitorRoutes {
      iface = w0IF;
      ips = [
        w0Mon1
        w0Mon2
      ];
    }
    ++ mkMonitorRoutes {
      gateway = w1Gateway;
      ips = [
        w1Mon1
        w1Mon2
      ];
    };
}
