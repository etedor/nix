{
  config,
  globals,
  specialArgs,
  ...
}:

let
  rt-ggz = globals.routers.rt-ggz;
  rt-sea = globals.routers.rt-sea;
in
{
  age.secrets = {
    wg0-private-key = {
      file = "${specialArgs.secretsHost}/wg0-private-key.age";
      mode = "444";
    };
  };

  systemd.network =
    let
      wg = config.et42.router.wireguard;
    in
    {
      netdevs = {
        "10-wg0" = {
          netdevConfig = {
            Name = "wg0";
            Kind = "wireguard";
            MTUBytes = "1420";
          };
          wireguardConfig = {
            PrivateKeyFile = config.age.secrets.wg0-private-key.path;
            ListenPort = 51820;
          };
          wireguardPeers = [
            {
              Endpoint = "${rt-sea.interfaces.ens3}:51820";
              PublicKey = wg.publicKeys.rt-sea.wg0;
              AllowedIPs = [ "0.0.0.0/0" ];
            }
          ];
        };
      };

      networks = {
        "10-wg0" = {
          matchConfig.Name = "wg0";
          address = [ "${rt-ggz.interfaces.wg0}/31" ];
        };
      };
    };
}
