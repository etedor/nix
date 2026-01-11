{
  globals,
  pkgs,
  ...
}:

let
  rt-ggz = globals.routers.rt-ggz;
  rt-sea = globals.routers.rt-sea;

  network = import ./network.nix;
  classes = import ./classes.nix;
  reservations = import ./reservations.nix;
in
{
  et42.router.dhcp = {
    enable = true;
    inherit network classes reservations;

    sharedNetworkName = globals.zone;
    dnsServers = [
      rt-ggz.interfaces.lo0
      rt-sea.interfaces.lo0
    ];
    domainName = globals.zone;
    ntpServer = globals.hosts.ntp.ip;

    authorizedRelayAgents = [
      "10.0.12.1"
    ];

    # override lease timers
    validLifetime = 86400;
    renewTimer = 43200;
    rebindTimer = 75600;

    # custom option definitions
    optionDefs = [
      {
        name = "apc-cookie";
        code = 1;
        space = "vendor-encapsulated-options-space";
        type = "string";
      }
    ];

    hooksLibraries =
      let
        hooks = "lib/kea/hooks";
      in
      [
        {
          library = "${pkgs.kea}/${hooks}/libdhcp_lease_query.so";
          parameters = {
            requesters = [
              "127.0.0.1"
              "10.0.2.32" # sw-garage
            ];
          };
        }
      ];
  };
}
