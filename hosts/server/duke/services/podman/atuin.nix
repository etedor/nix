{
  config,
  lib,
  ...
}:

{
  virtualisation.quadlet.containers.atuin-db = {
    containerConfig = {
      image = "docker.io/library/postgres:14";

      networks = [ "10-default" ];

      environments = {
        POSTGRES_USER = "atuin";
        POSTGRES_PASSWORD = "atuin";
        POSTGRES_DB = "atuin";
      };

      volumes = [
        "atuin_db:/var/lib/postgresql/data"
      ];
    };

    serviceConfig = {
      Restart = "always";
    };
  };

  virtualisation.quadlet.containers.atuin = {
    containerConfig = {
      image = "ghcr.io/atuinsh/atuin:v18.4.0";
      exec = "server start";

      networks = [ "10-default" ];

      environments = {
        ATUIN_HOST = "0.0.0.0";
        ATUIN_PORT = "8888";
        ATUIN_OPEN_REGISTRATION = "true";
        ATUIN_DB_URI = "postgres://atuin:atuin@atuin-db/atuin";
      };

      publishPorts = [
        "8888:8888"
      ];
    };

    serviceConfig = {
      Restart = "always";
    };

    unitConfig = {
      After = [ "atuin-db.service" ];
      Requires = [ "atuin-db.service" ];
    };
  };

  services.nginx.virtualHosts = lib.mkMerge [
    (config.et42.server.nginx.mkVirtualHost {
      subdomain = "atuin";
      proxyPass = "http://127.0.0.1:8888";
    })
  ];
}
