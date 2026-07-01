{
  config,
  globals,
  lib,
  ...
}:

{
  virtualisation.quadlet.containers.tidarr = {
    containerConfig = {
      image = "docker.io/cstaelen/tidarr:1.2.3";

      networks = [ "10-bulk" ];

      environments = {
        PUID = "1000";
        PGID = "1000";
        TZ = globals.tz;
      };

      volumes = [
        "tidarr_config:/shared"
        "/pool0/media/downloads/tidarr:/music"
      ];

      publishPorts = [
        "8484:8484"
      ];
    };

    serviceConfig = {
      Restart = "always";
    };
  };

  services.nginx.virtualHosts = lib.mkMerge [
    (config.et42.server.nginx.mkVirtualHost {
      subdomain = "tidal";
      proxyPass = "http://127.0.0.1:8484";
    })
  ];
}
