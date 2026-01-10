{
  config,
  globals,
  lib,
  ...
}:

{
  virtualisation.quadlet.containers.sabnzbd = {
    containerConfig = {
      image = "lscr.io/linuxserver/sabnzbd:4.5.1";

      networks = [
        "10-bulk"
        "99-media"
      ];

      environments = {
        PUID = "1000";
        PGID = "1000";
        TZ = globals.tz;
      };

      volumes = [
        "sabnzbd_config:/config"
        "/pool0/media/downloads:/media/downloads"
      ];

      publishPorts = [
        "8080:8080"
      ];
    };

    serviceConfig = {
      Restart = "always";
    };
  };

  services.nginx.virtualHosts = lib.mkMerge [
    (config.et42.server.nginx.mkVirtualHost {
      subdomain = "nzb";
      proxyPass = "http://127.0.0.1:8080";
    })
  ];
}
