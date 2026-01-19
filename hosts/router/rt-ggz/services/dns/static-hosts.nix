{ globals }:

{
  "brother" = "10.0.11.16";
  "docker-home" = "10.0.8.16";
  "duke" = "10.0.4.32";
  "ntp" = "10.0.2.16";
  "opengear" = "10.0.2.17";

  "rt-ggz" = globals.routers.rt-ggz.interfaces.lo0;
  "rt-sea" = globals.routers.rt-sea.interfaces.lo0;

  "sw-garage" = "10.0.2.32";
  "sw-living-room" = "10.0.2.33";
  "sw-office" = "10.0.2.34";
  "sw-playroom" = "10.0.2.35";

  "*" = "10.0.4.32";
}
