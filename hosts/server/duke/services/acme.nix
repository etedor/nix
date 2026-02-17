{
  config,
  globals,
  specialArgs,
  ...
}:

{
  age.secrets.acme = {
    file = "${specialArgs.secretsHost}/acme.age";
    mode = "400";
    owner = "acme";
    group = "acme";
  };

  security.acme = {
    acceptTerms = true;
    defaults.email = "admin@${globals.zones.home}";

    certs."${globals.zones.home}" = {
      domain = "${globals.zones.home}";
      extraDomainNames = [ "*.${globals.zones.home}" ];
      dnsProvider = "cloudflare";
      dnsPropagationCheck = true;
      dnsResolver = "1.1.1.1:53";
      credentialsFile = config.age.secrets.acme.path;
    };
  };
}
