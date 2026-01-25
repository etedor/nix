{ lib, ... }:

let
  multicastVlans = [ 8 10 ];

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
in
{
  services.frr = {
    pimd.enable = true;
    config = frrVlanConfig;
  };

  systemd.network.networks = networkConfigs;
}
