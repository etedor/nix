{
  config,
  globals,
  lib,
  ...
}:

{
  virtualisation.quadlet.containers.jellyfin = {
    containerConfig = {
      image = "lscr.io/linuxserver/jellyfin:10.10.7";

      networks = [
        "10-default"
        "99-media"
      ];

      environments = {
        PUID = "1000";
        PGID = "1000";
        TZ = globals.tz;
        JELLYFIN_PublishedServerUrl =
          let
            first = list: builtins.elemAt list 0;
            cidrAddress = first config.systemd.network.networks."30-lan0".networkConfig.Address;
            ipAddress = builtins.head (builtins.match "([0-9.]+).*" cidrAddress);
          in
          ipAddress;
      };

      volumes = [
        "jellyfin_config:/config"
        "/pool0/media/library/movies:/media/library/movies"
        "/pool0/media/library/tv:/media/library/tv"
        "/pool0/media/library/tv-daily:/media/library/tv-daily"
      ];

      publishPorts = [
        "8096:8096"
        "8920:8920"
        "1900:1900/udp"
        "7359:7359/udp"
      ];
    };

    serviceConfig = {
      Restart = "always";
    };
  };

  services.nginx.virtualHosts = lib.mkMerge [
    (config.et42.server.nginx.mkVirtualHost {
      subdomain = "jf";
      proxyPass = "http://127.0.0.1:8096";
      adminOnly = false;
      allowIPs = globals.networks.admin ++ globals.networks.family;
    })
  ];

  networking.firewall = {
    allowedTCPPorts = [
      8096
      8920
    ];
    allowedUDPPorts = [
      1900
      7359
    ];
  };
}
