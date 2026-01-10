{
  config,
  globals,
  mkModule,
  specialArgs,
  ...
}:

mkModule {
  shared = {

  };

  linux = {
    age.secrets.mailgun = {
      file = "${specialArgs.secretsCommon}/mailgun.age";
      mode = "400";
      owner = "root";
      group = "root";
    };

    programs.msmtp = {
      enable = true;
      setSendmail = true;

      defaults = {
        tls = true;
        tls_starttls = true;
        tls_trust_file = "/etc/ssl/certs/ca-certificates.crt";
      };

      accounts = {
        default = {
          host = "smtp.mailgun.org";
          port = 587;
          auth = true;
          from = "${config.networking.hostName}@mg.${globals.zone}";
          user = "system@mg.${globals.zone}";
          passwordeval = "cat ${config.age.secrets.mailgun.path}";
        };
      };
    };
  };

  darwin = {

  };
}
