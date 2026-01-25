# VLAN to subnet mapping
{
  vlans = {
    vlan2 = {
      subnet = "10.0.2.0/24";
      router = "10.0.2.1";
      description = "Infrastructure";
      pools = [
        {
          pool = "10.0.2.16 - 10.0.2.31";
          client-classes = [ "vlan2-services" ];
        }
        {
          pool = "10.0.2.32 - 10.0.2.39";
          client-classes = [ "vlan2-sw" ];
        }
        {
          pool = "10.0.2.40 - 10.0.2.47";
          client-classes = [ "vlan2-ap" ];
        }
        {
          pool = "10.0.2.48 - 10.0.2.63";
          client-classes = [ "vlan2-pd" ];
        }
        {
          pool = "10.0.2.192 - 10.0.2.254";
          client-classes = [ "vlan2" ];
        }
      ];
    };

    vlan4 = {
      subnet = "10.0.4.0/24";
      router = "10.0.4.1";
      description = "Servers";
      pools = [
        {
          pool = "10.0.4.32 - 10.0.4.63";
          client-classes = [ "vlan4-servers" ];
        }
        {
          pool = "10.0.4.192 - 10.0.4.254";
          client-classes = [ "vlan4" ];
        }
      ];
    };

    vlan8 = {
      subnet = "10.0.8.0/23";
      router = "10.0.8.1";
      description = "Clients";
      pools = [
        {
          pool = "10.0.8.16 - 10.0.8.31";
          client-classes = [ "vlan8-trust3-services" ];
        }
        {
          pool = "10.0.8.32 - 10.0.8.63";
          client-classes = [ "vlan8-trust3" ];
        }
        {
          pool = "10.0.9.16 - 10.0.9.31";
          client-classes = [ "vlan8-trust2-services" ];
        }
        {
          pool = "10.0.9.32 - 10.0.9.63";
          client-classes = [ "vlan8-trust2-upnp" ];
        }
        {
          pool = "10.0.9.64 - 10.0.9.95";
          client-classes = [ "vlan8-trust2-sonos" ];
        }
        {
          pool = "10.0.9.192 - 10.0.9.254";
          client-classes = [ "vlan8-trust2" ];
        }
      ];
    };

    vlan10 = {
      subnet = "10.0.10.0/23";
      router = "10.0.10.1";
      description = "Things";
      pools = [
        {
          pool = "10.0.10.16 - 10.0.10.31";
          client-classes = [ "vlan10-trust1-services" ];
        }
        {
          pool = "10.0.10.32 - 10.0.10.63";
          client-classes = [ "vlan10-trust1-isolate" ];
        }
        {
          pool = "10.0.10.64 - 10.0.10.95";
          client-classes = [ "vlan10-trust1-lifx" ];
        }
        {
          pool = "10.0.10.192 - 10.0.10.254";
          client-classes = [ "vlan10-trust1" ];
        }
        {
          pool = "10.0.11.16 - 10.0.11.31";
          client-classes = [ "vlan10-trust0-services" ];
        }
        {
          pool = "10.0.11.32 - 10.0.11.63";
          client-classes = [ "vlan10-trust0-wemo" ];
        }
        {
          pool = "10.0.11.64 - 10.0.11.95";
          client-classes = [ "vlan10-trust0-kasa" ];
        }
        {
          pool = "10.0.11.192 - 10.0.11.254";
          client-classes = [ "vlan10-trust0" ];
        }
      ];
    };

    vlan16 = {
      subnet = "10.0.16.0/24";
      router = "10.0.16.1";
      description = "Guests";
      pools = [
        {
          pool = "10.0.16.192 - 10.0.16.254";
          client-classes = [ "vlan16" ];
        }
      ];
    };

    vlan32 = {
      subnet = "10.0.32.0/24";
      router = "10.0.32.1";
      description = "Lab";
      pools = [
        {
          pool = "10.0.32.192 - 10.0.32.254";
          client-classes = [ "vlan32" ];
        }
      ];
    };
  };
}
