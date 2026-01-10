{
  config,
  globals,
  lib,
  ...
}:

{
  virtualisation.quadlet.containers.radarr = {
    containerConfig = {
      image = "lscr.io/linuxserver/radarr:5.23.3";

      networks = [
        "10-default"
        "99-media"
      ];

      environments = {
        PUID = "1000";
        PGID = "1000";
        TZ = globals.tz;
      };

      volumes = [
        "radarr_config:/config"
        "/pool0/media/downloads:/media/downloads"
        "/pool0/media/library/movies:/media/library/movies"
      ];

      publishPorts = [
        "7878:7878"
      ];
    };

    serviceConfig = {
      Restart = "always";
    };
  };

  services.nginx.virtualHosts = lib.mkMerge [
    (config.et42.server.nginx.mkVirtualHost {
      subdomain = "movies";
      proxyPass = "http://127.0.0.1:7878";
    })
  ];
}
