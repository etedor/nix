{ ... }:

{
  virtualisation.quadlet.containers.difc = {
    containerConfig = {
      image = "docker.io/tigerblue77/dell_idrac_fan_controller:latest";

      environments = {
        IDRAC_HOST = "local";
        FAN_SPEED = "5";
        CPU_TEMPERATURE_THRESHOLD = "80"; # intel xeon e5-2695 v4 (tcase = 84°C)
        CHECK_INTERVAL = "60";
        DISABLE_THIRD_PARTY_PCIE_CARD_DELL_DEFAULT_COOLING_RESPONSE = "true";
        KEEP_THIRD_PARTY_PCIE_CARD_COOLING_RESPONSE_STATE_ON_EXIT = "false";
      };

      devices = [
        "/dev/ipmi0:/dev/ipmi0:rw"
      ];
    };

    serviceConfig = {
      Restart = "always";
    };
  };
}
