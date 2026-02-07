{
  ...
}:

{
  et42.router.cake = {
    enable = true;

    interfaces.wan0 = {
      device = "wan0";
      linkType = "lte";
      egress = {
        Bandwidth = "20Mbit";
        AckFilter = true;
      };
      ingress = {
        Bandwidth = "5Mbit";
        AutoRateIngress = true;
        AckFilter = true;
      };
    };
  };
}
