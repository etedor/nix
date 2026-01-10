{
  config,
  lib,
  ...
}:

{
  virtualisation.quadlet.containers.flame = {
    containerConfig = {
      image = "pawelmalak/flame:2.3.1";
      networks = [ "10-default" ];

      volumes = [
        "flame_data:/app/data"
      ];

      publishPorts = [
        "5005:5005"
      ];
    };

    serviceConfig = {
      Restart = "always";
    };
  };

  services.nginx.virtualHosts = lib.mkMerge [
    (config.et42.server.nginx.mkVirtualHost {
      subdomain = "go";
      proxyPass = "http://127.0.0.1:5005";
    })
  ];
}
