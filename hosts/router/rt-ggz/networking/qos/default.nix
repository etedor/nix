{
  config,
  pkgs,
  ...
}:

let
  cakeCfg = config.et42.router.cake;
  wan0Ingress = cakeCfg._profiles.wan0.ingress;
in
{
  et42.router.cake = {
    enable = true;

    interfaces.wan0 = {
      device = "wan0";
      linkType = "docsis";
      egress = {
        Bandwidth = "240Mbit";
        AckFilter = false;
      };
      ingress = {
        Bandwidth = "2000Mbit"; # baseline
        AckFilter = false;
      };
    };

    interfaces.wan1 = {
      device = "wan1";
      linkType = "lte";
      egress = {
        Bandwidth = "20Mbit";
        AckFilter = true;
      };
      ingress = {
        Bandwidth = "5Mbit";
        AutoRateIngress = true;
        AckFilter = true;
      };
    };
  };

  # dynamic bandwidth switching based on traffic type
  systemd.services.cake-governor = {
    description = "CAKE Governor";
    after = [
      "qos-init.service"
      "nftables.service"
    ];
    requires = [
      "qos-init.service"
      "nftables.service"
    ];
    wantedBy = [ "multi-user.target" ];
    path = [
      pkgs.bc
      pkgs.coreutils
      pkgs.gnugrep
      pkgs.iproute2
      pkgs.nftables
      pkgs.util-linux
    ];
    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.bash}/bin/bash ${./cake-governor.sh}";
      Restart = "always";
      RestartSec = "10s";
    };
    environment = {
      CAKE_IFB_DEVICE = "ifb4wan0";
      CAKE_BASERATE = "2000";
      CAKE_POLL_INTERVAL = "10";
      CAKE_IDLE_TIMEOUT = "120";
      CAKE_RTT = wan0Ingress.RTT;
      CAKE_OVERHEAD = toString wan0Ingress.OverheadBytes;
    };
  };
}
