# M4 Mac mini

{
  globals,
  ...
}:

let
  user1 = globals.users 1;
in
{
  imports = [
    ./apps
    ./desktop
    ./display.nix
    ./mounts.nix
  ];

  networking.computerName = "Garage Mac Mini";
  networking.hostName = "garage";

  users.users.${user1.name} = {
    name = user1.name;
    description = user1.fullName;
    home = "/Users/${user1.name}";
    uid = 502;
  };
  home-manager.users.${user1.name}.home.stateVersion = "25.11";
}
