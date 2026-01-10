{
  config,
  globals,
  lib,
  ...
}:

{
  virtualisation.quadlet.containers.prowlarr = {
    containerConfig = {
      image = "lscr.io/linuxserver/prowlarr:1.35.1";

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
        "prowlarr_config:/config"
      ];

      publishPorts = [
        "9696:9696"
      ];
    };

    serviceConfig = {
      Restart = "always";
    };
  };

  services.nginx.virtualHosts = lib.mkMerge [
    (config.et42.server.nginx.mkVirtualHost {
      subdomain = "prowl";
      proxyPass = "http://127.0.0.1:9696";
    })
  ];
}
