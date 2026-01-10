{
  config,
  globals,
  lib,
  ...
}:

{
  virtualisation.quadlet.containers.freshrss = {
    containerConfig = {
      image = "lscr.io/linuxserver/freshrss:version-1.26.0";

      networks = [ "10-default" ];

      environments = {
        PUID = "1000";
        PGID = "1000";
        TZ = globals.tz;
      };

      volumes = [
        "freshrss_config:/config"
      ];

      publishPorts = [
        "8091:80"
      ];
    };

    serviceConfig = {
      Restart = "always";
    };
  };

  services.nginx.virtualHosts = lib.mkMerge [
    (config.et42.server.nginx.mkVirtualHost {
      subdomain = "rss";
      proxyPass = "http://127.0.0.1:8091";
    })
  ];
}
