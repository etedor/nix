[
  {
    name = "apple-tv";
    macs = [
      "6c:4a:85:3d:23:2f" # office
      "f0:b3:ec:70:24:35" # living-room
      "f0:b3:ec:7e:27:c4" # playroom
    ];
  }
  {
    name = "aurora";
    macs = [
      "2c:8d:b1:e9:f5:34"
      "50:eb:f6:25:9b:77"
    ];
  }
  {
    name = "bambu-labs";
    macs = [
      "a0:85:e3:ea:d7:40"
    ];
  }
  {
    name = "bosch";
    macs = [
      "68:a4:0e:5d:4c:c6" # fridge
    ];
  }
  {
    name = "brother";
    macs = [
      "ac:50:de:af:ea:12"
    ];
  }
  {
    name = "cafe";
    macs = [
      "fc:b9:7e:8e:a0:14"
    ];
  }
  {
    name = "carbon";
    macs = [
      "dc:93:96:00:c4:c0"
    ];
  }
  {
    name = "daikin";
    macs = [
      "d8:10:68:49:32:f1"
    ];
  }
  {
    name = "enphase";
    macs = [
      "e0:5a:1b:56:52:38"
    ];
  }
  {
    name = "garage";
    macs = [
      "62:79:76:25:d4:3c"
    ];
  }
  {
    name = "govee";
    macs = [
      "d4:ad:fc:2c:77:56"
    ];
  }
  {
    name = "logitech";
    macs = [
      "44:73:d6:20:c9:52" # doorbell
    ];
  }
  {
    name = "machina";
    macs = [
      "1c:1d:d3:ec:cf:8b" # wired
      "1c:1d:d3:f2:03:77" # wireless
    ];
  }
  {
    name = "netatmo";
    macs = [
      "70:ee:50:06:0b:ee"
    ];
  }
  {
    name = "nintendo-switch";
    macs = [
      "8c:ae:4c:d6:0f:90"
      "8c:ae:4c:d6:48:37"
      "e8:da:20:c1:d0:cf"
    ];
  }
  {
    name = "petlibro";
    macs = [
      "e0:09:bf:01:5f:b9"
      "e0:09:bf:01:64:77"
    ];
  }
  {
    name = "pine";
    macs = [
      "fe:48:38:64:31:fa"
    ];
  }
  {
    name = "rainbird";
    macs = [
      "4c:a1:61:04:27:d0"
    ];
  }
  {
    name = "ratgdo";
    macs = [
      "24:d7:eb:db:fa:6c"
      "cc:7b:5c:4b:fc:26"
    ];
  }
  {
    name = "roomba";
    macs = [
      "d0:c5:d3:cc:8c:6a"
    ];
  }
  {
    name = "slipgate";
    macs = [
      "b8:59:9f:c6:41:fa"
      "b8:59:9f:c6:41:fb"
    ];
  }

  {
    name = "steam-deck";
    macs = [
      "10:82:86:19:37:38"
      "14:13:33:12:cc:73"
    ];
  }
  {
    name = "sole";
    macs = [
      "b8:13:32:98:50:ce" # treadmill
    ];
  }

  {
    name = "tv-living-room";
    macs = [
      "bc:7e:8b:79:85:f6"
      "5c:c1:d7:62:c7:82"
    ];
  }
  {
    name = "tv-office";
    macs = [
      "80:47:86:e6:08:b3"
    ];
  }
  {
    name = "tv-playroom";
    macs = [
      "00:bd:3e:b6:3d:a6"
    ];
  }
  {
    name = "winix";
    macs = [
      "84:72:07:4f:08:46"
      "84:72:07:4f:20:eb"
    ];
  }
  {
    name = "work";
    macs = [
      "5c:9b:a6:9f:8f:02" # phone
      "84:2f:57:d1:14:5a" # laptop
    ];
  }

  # OUI-based classes
  {
    name = "apc";
    ouis = [ "00:c0:b7" ];
    options = [
      {
        name = "vendor-encapsulated-options";
        code = 43;
        space = "dhcp4";
        always-send = true;
      }
      {
        name = "apc-cookie";
        space = "vendor-encapsulated-options-space";
        data = "1APC";
      }
    ];
  }
  {
    name = "ruckus-wifi";
    ouis = [
      "78:9f:6a"
    ];
  }
  {
    name = "kasa";
    ouis = [
      "00:31:92"
      "10:27:f5"
      "50:c7:bf"
      "68:ff:7b"
      "ac:84:c6"
      "b0:95:75"
    ];
  }
  {
    name = "lifx";
    ouis = [
      "d0:73:d5"
    ];
  }

  {
    name = "nest";
    ouis = [
      "18:b4:30"
      "64:16:66"
    ];
  }
  {
    name = "sonos";
    ouis = [
      "00:0e:58"
      "34:7e:5c"
      "38:42:0b"
      "48:a6:b8"
      "54:2a:1b"
      "5c:aa:fd"
      "74:ca:60"
      "78:28:ca"
      "80:4a:f2"
      "94:9f:3e"
      "b8:e9:37"
      "c4:38:75"
      "ea:be:a7"
      "f0:f6:c1"
    ];
  }
  {
    name = "wemo";
    ouis = [
      "14:91:82"
      "58:ef:68"
      "60:38:e0"
      "94:10:3e"
      "b4:75:0e"
    ];
  }
  {
    name = "test-device";
    ouis = [
      "c6:b6:3c"
    ];
    options = [
      {
        name = "dhcp-lease-time";
        code = 51;
        data = "30";
      }
      {
        name = "dhcp-renewal-time";
        code = 58;
        data = "15";
      }
      {
        name = "dhcp-rebinding-time";
        code = 59;
        data = "25";
      }
      {
        name = "dhcp-server-identifier";
        code = 54;
        data = "10.0.8.1";
      }
    ];
  }

  # === classes of classes ===
  {
    name = "vlan2-ap";
    memberOf = [
      "ruckus-wifi"
    ];
    exclusive = false;
    exclusionGroup = "vlan2";
  }
  {
    name = "vlan2";
    interface = "vlan2";
    exclusive = true;
    exclusionGroup = "vlan2";
  }

  {
    name = "vlan4";
    interface = "vlan4";
    exclusive = true;
    exclusionGroup = "vlan4";
  }

  {
    name = "vlan8-trust2-services";
    memberOf = [
      "apple-tv"
    ];
    exclusive = false;
    exclusionGroup = "vlan8";
  }
  {
    name = "vlan8-trust2-upnp";
    memberOf = [
      "aurora"
      "nintendo-switch"
      "slipgate"
      "steam-deck"
    ];
    exclusive = false;
    exclusionGroup = "vlan8";
  }
  {
    name = "vlan8-trust2-sonos";
    memberOf = [
      "test-device"
      "sonos"
    ];
    exclusive = false;
    exclusionGroup = "vlan8";
  }
  {
    name = "vlan10-trust1-isolate";
    memberOf = [
      "bosch"
      "daikin"
      "enphase"
      "nest"
      "netatmo"
      "petlibro"
      "sole"
      "tv-living-room"
      "winix"
      "work"
    ];
    exclusive = false;
    exclusionGroup = "vlan10";
  }
  {
    name = "vlan10-trust1-lifx";
    memberOf = [
      "lifx"
    ];
    exclusive = false;
    exclusionGroup = "vlan10";
  }
  {
    name = "vlan10-trust0-services";
    memberOf = [
      "brother"
    ];
    exclusive = false;
    exclusionGroup = "vlan10";
  }
  {
    name = "vlan10-trust0-wemo";
    memberOf = [
      "wemo"
    ];
    exclusive = false;
    exclusionGroup = "vlan10";
  }
  {
    name = "vlan10-trust0-kasa";
    memberOf = [
      "kasa"
    ];
    exclusive = false;
    exclusionGroup = "vlan10";
  }

  {
    name = "vlan8-trust3";
    memberOf = [
      "carbon"
      "garage"
      "machina"
      "pine"
    ];
    routes = [
      {
        prefix = "0.0.0.0/1";
        gateway = "10.0.8.1";
      }
      {
        prefix = "128.0.0.0/1";
        gateway = "10.0.8.1";
      }
    ];
    exclusive = true;
    exclusionGroup = "vlan8";
  }
  {
    name = "vlan10-trust1";
    memberOf = [
      "bambu-labs"
      "cafe"
      "logitech"
      "rainbird"
    ];
    exclusive = true;
    exclusionGroup = "vlan10";
  }
  {
    name = "vlan10-trust0";
    memberOf = [
      "tv-office"
      "tv-playroom"
    ];
    ssidSuffixes = [
      "Things"
    ];
    exclusive = true;
    exclusionGroup = "vlan10";
  }
  {
    name = "vlan10";
    interface = "vlan10";
    exclusive = true;
    exclusionGroup = "vlan10";
  }
  {
    name = "vlan8-trust2";
    interface = "vlan8";
    exclusive = true;
    exclusionGroup = "vlan8";
  }

  {
    name = "vlan16";
    interface = "vlan16";
    exclusive = true;
    exclusionGroup = "vlan16";
  }

  {
    name = "vlan32";
    interface = "vlan32";
    exclusive = true;
    exclusionGroup = "vlan32";
  }
]
