# M4 Max Mac Studio

{ ... }:

{
  imports = [
    ./ai
    ./apps
    ./deploy.nix
    ./desktop
    ./display.nix
  ];

  networking.computerName = "Machina";
  networking.hostName = "machina";

  et42.device.hammerspoon = {
    padding = 10;
    enableInputToggle = true;
  };
}
