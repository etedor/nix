{ lib, pkgs, ... }:

{
  boot.kernel.sysctl."net.ipv4.ip_forward" = 1;

  virtualisation.containers.storage.settings = {
    storage = {
      driver = "overlay";
      graphroot = "/pool0/podman/storage";
      runroot = "/run/containers/storage";
    };
  };

  virtualisation.containers.containersConf.settings = {
    network = {
      dns_servers = [ "10.127.0.1" ];
    };
  };

  virtualisation.podman = {
    enable = true;
    dockerCompat = false; # keep docker separate during migration
  };

  virtualisation.quadlet = {
    autoEscape = true;

    networks."10-bulk" = {
      networkConfig = {
        podmanArgs = [
          "--interface-name"
          "bulk0"
        ];
      };
    };

    networks."10-default" = {
      networkConfig = {
        podmanArgs = [
          "--interface-name"
          "default0"
        ];
      };
    };
  };

  systemd.slices.bulk = {
    description = "Slice for low-priority bulk traffic (downloads, backups)";
    sliceConfig = { };
  };

  # reload netavark firewall rules after nftables restarts (e.g., nixos-rebuild)
  # upstream provides this but nixpkgs doesn't install it
  # https://github.com/containers/netavark/issues/1258
  systemd.services.nftables.serviceConfig.ExecStartPost = lib.mkAfter [
    (pkgs.writeShellScript "netavark-firewall-reload" ''
      export PATH="${pkgs.nftables}/bin:$PATH"
      ${pkgs.netavark}/bin/netavark firewall-reload
    '')
  ];
}
