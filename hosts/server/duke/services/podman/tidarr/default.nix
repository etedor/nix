{
  config,
  globals,
  lib,
  ...
}:

{
  virtualisation.quadlet.containers.tidarr = {
    containerConfig = {
      image = "docker.io/cstaelen/tidarr:1.1.5";

      networks = [ "10-bulk" ];

      environments = {
        PUID = "1000";
        PGID = "1000";
        TZ = globals.tz;
        TIDDL_PATH = "/shared/.tiddl";
        REACT_APP_TIDAL_COUNTRY_CODE = "US";
        REACT_APP_TIDARR_DEFAULT_QUALITY_FILTER = "all";
      };

      volumes = [
        "tidarr_config:/shared"
        "${./config.toml}:/shared/.tiddl/config.toml:ro"
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
