{
  config,
  globals,
  lib,
  pkgs,
  specialArgs,
  ...
}:

{
  age.secrets.smb-brother = {
    file = "${specialArgs.secretsHost}/smb-brother.age";
    mode = "400";
  };

  users.groups.paperless = { };

  users.users.brother = {
    isSystemUser = true;
    description = "Brother MFC-L2750DW";
    group = "paperless";
  };

  system.activationScripts.brotherSambaSetup = {
    text = ''
      PATH=$PATH:${lib.makeBinPath [ pkgs.samba ]}
      if [ -f "${config.age.secrets.smb-brother.path}" ]; then
        password=$(cat "${config.age.secrets.smb-brother.path}")
        printf "%s\n%s\n" "$password" "$password" | smbpasswd -a -s brother
      fi
    '';
    deps = [
      "agenix"
      "users"
    ];
  };

  virtualisation.quadlet.containers.paperless-redis = {
    containerConfig = {
      image = "docker.io/library/redis:7";

      networks = [ "10-default" ];

      volumes = [
        "paperless_redis_data:/data"
      ];
    };

    serviceConfig = {
      Restart = "always";
    };
  };

  virtualisation.quadlet.containers.paperless = {
    containerConfig = {
      image = "ghcr.io/paperless-ngx/paperless-ngx:latest";

      networks = [ "10-default" ];

      environments = {
        PAPERLESS_REDIS = "redis://paperless-redis:6379";
        PAPERLESS_DBENGINE = "sqlite";
        PAPERLESS_TIME_ZONE = globals.tz;
        PAPERLESS_OCR_LANGUAGE = "eng";
        PAPERLESS_ALLOWED_HOSTS = "paperless.${globals.zone},127.0.0.1,localhost";
        PAPERLESS_CSRF_TRUSTED_ORIGINS = "https://paperless.${globals.zone}";
        PAPERLESS_ADMIN_USER = "admin";
        PAPERLESS_URL = "https://paperless.${globals.zone}";
        PAPERLESS_CONSUMPTION_DIR = "/usr/src/paperless/consume";
      };

      environmentFiles = [ config.age.secrets.paperless.path ];

      volumes = [
        "paperless_data:/usr/src/paperless/data"
        "paperless_media:/usr/src/paperless/media"
        "/pool0/paperless/consume:/usr/src/paperless/consume"
      ];

      publishPorts = [
        "8000:8000"
      ];
    };

    serviceConfig = {
      Restart = "always";
      After = [ "paperless-redis.service" ];
      Requires = [ "paperless-redis.service" ];
    };
  };

  services.nginx.virtualHosts = lib.mkMerge [
    (config.et42.server.nginx.mkVirtualHost {
      subdomain = "paperless";
      proxyPass = "http://127.0.0.1:8000";
    })
  ];
}
