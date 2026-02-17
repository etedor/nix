{
  globals,
  ...
}:

let
  rt-ggz2 = globals.routers.rt-ggz2;

  mgmtZone = globals.zones.mgmt;

  network = import ./network.nix;
  classes = import ./classes.nix;
  reservations = import ./reservations.nix;
in
{
  et42.router.dhcp = {
    enable = true;
    inherit network classes reservations;

    sharedNetworkName = mgmtZone;
    dnsServers = [ rt-ggz2.interfaces.lo0 ];
    domainName = mgmtZone;
    ntpServer = globals.hosts.ntp.ip;

    validLifetime = 86400;
    renewTimer = 43200;
    rebindTimer = 75600;
  };

  # override interface list — rt-ggz2 has no VLANs, DHCP serves lan0 only
  services.kea.dhcp4.settings."interfaces-config".interfaces = [ "lan0" ];
}
