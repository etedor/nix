{
  globals,
  ...
}:

let
  duke = globals.hosts.duke;
  zone = globals.routers.rt-sea.zones;
in
{
  rules = [
    {
      name = "https to duke";
      iifs = zone.untrust;
      ip = duke.ip;
      pt = 443;
      proto = "tcp";
      log = true;
    }
  ];
}
