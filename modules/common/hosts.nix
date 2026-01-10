{
  globals,
  lib,
  ...
}:

{
  options.et42.hosts = {
    ntp = lib.mkOption {
      type = lib.types.attrs;
      description = "NTP server definition";
      default = {
        name = "ntp.${globals.zone}";
        ip = "10.0.2.16";
      };
    };
  };
}
