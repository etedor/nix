{ globals }:

{
  # infrastructure
  "rt-ggz2" = globals.routers.rt-ggz2.interfaces.lo0;
  "opengear" = "10.1.200.17";

  # switches
  "sw-garage" = "10.1.200.32";
  "sw-living-room" = "10.1.200.33";
  "sw-office" = "10.1.200.34";
  "sw-playroom" = "10.1.200.35";
}
