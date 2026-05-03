{
  config,
  globals,
  inputs,
  specialArgs,
  ...
}:

let
  user0 = globals.users 0;
in
{
  imports = [ inputs.ledger.nixosModules.default ];

  age.secrets.ledger = {
    file = "${specialArgs.secretsHost}/ledger.age";
    owner = "ledger";
    mode = "0400";
  };

  services.ledger = {
    enable = true;
    configFile = config.age.secrets.ledger.path;
  };

  # Admin CLI scoped to the operator's shell only — keeps the daemon
  # binary out of root's PATH on what is otherwise a one-family appliance.
  home-manager.users.${user0.name}.home.packages = [
    config.services.ledger.adminWrapper
  ];
}
