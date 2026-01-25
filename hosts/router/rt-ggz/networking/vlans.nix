{
  globals,
  lib,
  ...
}:

let
  vlans = {
    vlan2 = "10.0.2.1/24";
    vlan4 = "10.0.4.1/24";
    vlan8 = "10.0.8.1/23";
    vlan10 = "10.0.10.1/23";
    vlan16 = "10.0.16.1/24";
    vlan32 = "10.0.32.1/24";
  };

  # sort IP addresses by their network segment
  sortByThirdOctet =
    ipList:
    let
      # get the third octet from an IP address
      getThirdOctet =
        ip:
        let
          # extract IP without subnet mask if there is one
          ipOnly = builtins.elemAt (lib.splitString "/" ip) 0;
          octets = lib.splitString "." ipOnly;
          thirdOctet = lib.toInt (builtins.elemAt octets 2);
        in
        thirdOctet;

      cmpByOctet = a: b: getThirdOctet a < getThirdOctet b;
    in
    builtins.sort cmpByOctet ipList;

  # sort by VLAN number (vlan2, vlan4, vlan8, etc.)
  sortByVID =
    vlanList:
    let
      # extract number from VLAN name safely
      getVlanNum =
        name:
        let
          numStr = builtins.replaceStrings [ "vlan" ] [ "" ] name;
        in
        lib.toInt numStr;

      # comparison function
      cmpByVlanNum = a: b: getVlanNum a < getVlanNum b;
    in
    builtins.sort cmpByVlanNum vlanList;

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

    # keep the map for internal use
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
