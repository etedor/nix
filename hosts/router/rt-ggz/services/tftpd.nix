{
  globals,
  pkgs,
  ...
}:

let
  tftpAddr = globals.networks.ggz.tftp;
in
{
  # MTU 1500 macvlan on vlan2 — forces IP fragmentation for TFTP
  systemd.network.netdevs."45-vlan2-1500" = {
    netdevConfig = {
      Kind = "macvlan";
      Name = "vlan2-1500";
      MTUBytes = "1500";
    };
    macvlanConfig.Mode = "bridge";
  };

  systemd.network.networks."45-vlan2-1500" = {
    matchConfig.Name = "vlan2-1500";
    networkConfig = {
      Address = [ "${tftpAddr}/24" ];
      LinkLocalAddressing = "no";
    };
    linkConfig.RequiredForOnline = "no";

    # source policy route — egress via macvlan, not parent vlan2
    routingPolicyRules = [
      {
        From = "${tftpAddr}";
        Table = 200;
        Priority = 100;
      }
    ];
    routes = [
      {
        Table = 200;
        Destination = "10.0.2.0/24";
      }
    ];
  };

  systemd.network.networks."40-vlan2".networkConfig.MACVLAN = [ "vlan2-1500" ];

  boot.kernelModules = [ "nf_conntrack_tftp" ];

  systemd.services.tftpd = {
    description = "TFTP server";
    after = [
      "network.target"
      "sys-subsystem-net-devices-vlan2\\x2d1500.device"
    ];
    bindsTo = [ "sys-subsystem-net-devices-vlan2\\x2d1500.device" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      ExecStart = "${pkgs.tftp-hpa}/bin/in.tftpd -L -a ${tftpAddr}:69 -s /srv/tftp";
      DynamicUser = true;
      ReadOnlyPaths = [ "/srv/tftp" ];
      AmbientCapabilities = [
        "CAP_NET_BIND_SERVICE"
        "CAP_SYS_CHROOT"
      ];
      CapabilityBoundingSet = [
        "CAP_NET_BIND_SERVICE"
        "CAP_SYS_CHROOT"
      ];
      NoNewPrivileges = true;
      ProtectSystem = "strict";
      ProtectHome = true;
      PrivateTmp = true;
    };
  };

  systemd.tmpfiles.rules = [
    "d /srv/tftp 0755 root root -"
  ];
}
