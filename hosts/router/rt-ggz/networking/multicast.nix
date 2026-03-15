{ lib, globals, ... }:

let
  multicastVlans = [
    8
    10
  ];

  frrVlanConfig = lib.concatMapStringsSep "\n" (vlan: ''
    interface vlan${toString vlan}
     ip igmp
  '') multicastVlans;

  networkConfigs = lib.listToAttrs (
    map (vlan: {
      name = "40-vlan${toString vlan}";
      value = {
        linkConfig.Multicast = true;
      };
    }) multicastVlans
  );

  brother = globals.hosts.brother;
in
{
  services.frr = {
    pimd.enable = true;
    config = frrVlanConfig;
  };

  # mDNS reflection between client and things VLANs
  services.avahi = {
    enable = true;
    reflector = true;
    allowInterfaces = [
      "vlan8"
      "vlan10"
    ];
  };

  systemd.network.networks = networkConfigs;
}
