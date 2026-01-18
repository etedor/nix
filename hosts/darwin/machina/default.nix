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
    ultrawideLeftWidth = 0.25;
    ultrawideCenterWidth = 0.45;
    ultrawideRightWidth = 0.30;
    enableInputToggle = true;
  };
}
