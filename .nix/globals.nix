{ private }:

{
  globals = {
    keys = import ./keys.nix;
    users = i: builtins.elemAt private.users i;

    jumbo = 9198;
    tz = "America/Los_Angeles";
    zone = private.zone;
  };
}
