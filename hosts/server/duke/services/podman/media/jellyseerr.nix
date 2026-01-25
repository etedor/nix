{
  config,
  globals,
  lib,
  ...
}:

{
  virtualisation.quadlet.containers.jellyseerr = {
    containerConfig = {
      image = "fallenbagel/jellyseerr:2.5.2";

      networks = [
        "10-default"
        "99-media"
      ];

      environments = {
        PUID = "1000";
        PGID = "1000";
        LOG_LEVEL = "debug";
        TZ = globals.tz;
      };

      volumes = [
        "jellyseerr_config:/app/config"
      ];

      publishPorts = [
        "5055:5055"
      ];
    };

    serviceConfig = {
      Restart = "always";
    };
  };

  services.nginx.virtualHosts = lib.mkMerge [
    (config.et42.server.nginx.mkVirtualHost {
      subdomain = "requests";
      proxyPass = "http://127.0.0.1:5055";
      adminOnly = false;
      allowIPs = globals.networks.admin ++ globals.networks.family;
    })
  ];
}
