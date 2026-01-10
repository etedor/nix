{ ... }:

{
  virtualisation.quadlet.networks."99-media" = {
    networkConfig = {
      podmanArgs = [
        "--internal"
        "--interface-name"
        "media0"
      ];
    };
  };

  imports = [
    ./jellyfin.nix
    ./jellyseerr.nix
    ./prowlarr.nix
    ./radarr.nix
    ./sabnzbd.nix
    ./sonarr.nix
  ];
}
