{
  config,
  globals,
  lib,
  pkgs,
  specialArgs,
  ...
}:

{
  age.secrets = {
    paperless = {
      file = "${specialArgs.secretsHost}/paperless.age";
      mode = "400";
    };
    smb-brother = {
      file = "${specialArgs.secretsHost}/smb-brother.age";
      mode = "400";
    };
  };

  users.users.brother = {
    isSystemUser = true;
    description = "Brother MFC-L2750DW";
    group = "paperless";
    extraGroups = [ "paperless" ];
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

  services.paperless = {
    enable = false;
    mediaDir = "/pool0/paperless/media";
    consumptionDir = "/pool0/paperless/consume";
    passwordFile = config.age.secrets.paperless.path;
    settings = {
      PAPERLESS_ALLOWED_HOSTS = "paperless.${globals.zone},127.0.0.1,localhost";
      PAPERLESS_CSRF_TRUSTED_ORIGINS = "https://paperless.${globals.zone}";
    };
  };
}
