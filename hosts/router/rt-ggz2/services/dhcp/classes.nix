[
  # OUI-based classes
  {
    name = "switch";
    ouis = [
      "28:99:3a" # Arista
      "44:4c:a8" # Arista
    ];
  }
  {
    name = "ap-mgmt";
    ouis = [
      "78:9f:6a" # Ruckus
    ];
  }
  {
    name = "ups";
    ouis = [
      "00:c0:b7" # APC
      "00:20:85" # APC
    ];
  }
  {
    name = "opengear";
    ouis = [
      "00:13:c6" # Opengear
    ];
  }

  # catch-all for mgmt interface
  {
    name = "lan0";
    interface = "lan0";
    exclusive = true;
    exclusionGroup = "lan0";
  }
]
