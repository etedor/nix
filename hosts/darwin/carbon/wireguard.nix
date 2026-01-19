{
  globals,
  specialArgs,
  ...
}:

let
  user0 = globals.users 0;
in
{
  age.secrets.wg0-config = {
    file = "${specialArgs.secretsHost}/wg0-config.age";
    owner = user0.name;
    group = "staff";
    mode = "0400";
  };
}
