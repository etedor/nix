{
  globals,
  lib,
  ...
}:

let
  vlans = {
    vlan200 = "10.1.200.1/24";
  };

  # sort by VLAN number
  sortByVID =
    vlanList:
    let
      getVlanNum =
        name:
        let
          numStr = builtins.replaceStrings [ "vlan" ] [ "" ] name;
        in
        lib.toInt numStr;
      cmpByVlanNum = a: b: getVlanNum a < getVlanNum b;
    in
    builtins.sort cmpByVlanNum vlanList;

  # sort IP addresses by their third octet
  sortByThirdOctet =
    ipList:
    let
      getThirdOctet =
        ip:
        let
          ipOnly = builtins.elemAt (lib.splitString "/" ip) 0;
          octets = lib.splitString "." ipOnly;
          thirdOctet = lib.toInt (builtins.elemAt octets 2);
        in
        thirdOctet;
      cmpByOctet = a: b: getThirdOctet a < getThirdOctet b;
    in
    builtins.sort cmpByOctet ipList;

  vlanAddrsSorted = sortByThirdOctet (builtins.attrValues vlans);
  vlanNamesSorted = sortByVID (builtins.attrNames vlans);
in
{
  options.et42.router.vlan = {

    addrs = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = vlanAddrsSorted;
      description = "List of all configured VLAN addresses, sorted by IP address";
      readOnly = true;
    };

    names = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = vlanNamesSorted;
      description = "List of all configured VLANs, sorted by name";
      readOnly = true;
    };

    map = lib.mkOption {
      type = lib.types.attrs;
      default = vlans;
      internal = true;
      description = "Map of VLAN names to their IP addresses";
    };
  };

  config = {
    systemd.network.netdevs = lib.mapAttrs' (
      vlan: _ip:
      lib.nameValuePair "40-${vlan}" {
        netdevConfig = {
          Kind = "vlan";
          Name = vlan;
          MTUBytes = globals.jumbo;
        };
        vlanConfig.Id = lib.toInt (builtins.replaceStrings [ "vlan" ] [ "" ] vlan);
      }
    ) vlans;

    systemd.network.networks = lib.mapAttrs' (
      vlan: ip:
      lib.nameValuePair "40-${vlan}" {
        matchConfig.Name = vlan;
        networkConfig = {
          Address = [ ip ];
          LinkLocalAddressing = "no";
        };
        linkConfig.RequiredForOnline = "yes";
      }
    ) vlans;
  };
}
