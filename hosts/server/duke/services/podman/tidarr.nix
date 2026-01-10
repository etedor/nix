{
  config,
  globals,
  lib,
  ...
}:

{
  virtualisation.quadlet.containers.tidarr = {
    containerConfig = {
      image = "docker.io/cstaelen/tidarr:0.4.6";

      networks = [ "10-bulk" ];

      environments = {
        PUID = "1000";
        PGID = "1000";
        TZ = globals.tz;
        REACT_APP_TIDAL_COUNTRY_CODE = "US";
        REACT_APP_TIDARR_DEFAULT_QUALITY_FILTER = "all";
      };

      volumes = [
        "tidarr_config:/home/app/standalone/shared"
        "/pool0/media/downloads/tidarr:/home/app/standalone/library"
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
