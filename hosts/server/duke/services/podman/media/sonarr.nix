{
  config,
  globals,
  lib,
  ...
}:

{
  virtualisation.quadlet.containers.sonarr = {
    containerConfig = {
      image = "lscr.io/linuxserver/sonarr:4.0.14";

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
        "sonarr_config:/config"
        "/pool0/media/downloads:/media/downloads"
        "/pool0/media/library/tv:/media/library/tv"
        "/pool0/media/library/tv-daily:/media/library/tv-daily"
      ];

      publishPorts = [
        "8989:8989"
      ];
    };

    serviceConfig = {
      Restart = "always";
    };
  };

  services.nginx.virtualHosts = lib.mkMerge [
    (config.et42.server.nginx.mkVirtualHost {
      subdomain = "tv";
      proxyPass = "http://127.0.0.1:8989";
    })
  ];
}
