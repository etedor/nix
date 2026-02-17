{ globals }:

let
  # routers: name → loopback IP
  routerHosts = builtins.mapAttrs (_: r: r.interfaces.lo0) globals.routers;

  # hosts: name → IP
  globalHosts = builtins.mapAttrs (_: h: h.ip) globals.hosts;

in
{
  ${globals.zones.home} = routerHosts // globalHosts // {
    # non-nix devices
    "docker-home" = "10.0.8.16";
    "opengear" = "10.0.2.17";
    "sw-garage" = "10.0.2.32";
    "sw-living-room" = "10.0.2.33";
    "sw-office" = "10.0.2.34";
    "sw-playroom" = "10.0.2.35";
  };

  ${globals.zones.mgmt} = {
    "rt-ggz2" = globals.routers.rt-ggz2.interfaces.lo0;
    "opengear" = "10.1.200.17";
    "sw-garage" = "10.1.200.32";
    "sw-living-room" = "10.1.200.33";
    "sw-office" = "10.1.200.34";
    "sw-playroom" = "10.1.200.35";
  };
}
